use std::collections::HashMap;
use std::fmt::Debug;
use std::fs::File;
use std::path::Path;
use std::sync::Arc;

use anyhow::{anyhow, bail, Context, Result};
use flutter_rust_bridge::frb;
use log::{debug, error, info, warn};
use parking_lot::{Mutex, RwLock};
use serde::{Deserialize, Serialize};
use serde_json::json;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{Address, Hash, Hashable};
use xelis_common::network::Network;
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{FeeBuilder, TransactionTypeBuilder, TransferBuilder};
use xelis_common::transaction::BurnPayload;
pub use xelis_common::transaction::Transaction;
use xelis_common::utils::{format_coin, format_xelis};
use xelis_wallet::precomputed_tables;
pub use xelis_wallet::transaction_builder::TransactionBuilderState;
use xelis_wallet::wallet::{RecoverOption, Wallet};

use crate::api::table_generation::LogProgressTableGenerationReportFunction;
use crate::frb_generated::StreamSink;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SummaryTransaction {
    hash: String,
    fee: u64,
    transaction_type: TransactionTypeBuilder,
}

#[derive(Clone, Debug)]
pub struct Transfer {
    pub float_amount: f64,
    pub str_address: String,
    pub asset_hash: String,
    pub extra_data: Option<String>,
}

pub struct XelisWallet {
    wallet: Arc<Wallet>,
    pending_transactions: RwLock<HashMap<Hash, (Transaction, TransactionBuilderState)>>,
}

// Precomputed tables for the wallet
static CACHED_TABLES: Mutex<Option<precomputed_tables::PrecomputedTablesShared>> = Mutex::new(None);

pub async fn create_xelis_wallet(
    name: String,
    password: String,
    network: Network,
    seed: Option<String>,
    private_key: Option<String>,
    precomputed_tables_path: Option<String>,
) -> Result<XelisWallet> {
    let precomputed_tables = {
        let tables = CACHED_TABLES.lock().clone();
        match tables {
            Some(tables) => tables,
            None => {
                let precomputed_tables_size = if cfg!(target_arch = "wasm32") {
                    precomputed_tables::L1_LOW
                } else {
                    precomputed_tables::L1_FULL
                };
                let tables = precomputed_tables::read_or_generate_precomputed_tables(
                    precomputed_tables_path.as_deref(),
                    precomputed_tables_size,
                    LogProgressTableGenerationReportFunction,
                    true,
                )
                .await?;

                // It is done in two steps to avoid the "Future is not Send" error
                CACHED_TABLES.lock().replace(tables.clone());
                tables
            }
        }
    };

    let recover: Option<RecoverOption> = if let Some(seed) = seed.as_deref() {
        Some(RecoverOption::Seed(seed))
    } else if let Some(private_key) = private_key.as_deref() {
        Some(RecoverOption::PrivateKey(private_key))
    } else {
        None
    };

    let xelis_wallet = Wallet::create(&name, &password, recover, network, precomputed_tables)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
        pending_transactions: RwLock::new(HashMap::new()),
    })
}

pub async fn open_xelis_wallet(
    name: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
) -> Result<XelisWallet> {
    let precomputed_tables_size = if cfg!(target_arch = "wasm32") {
        precomputed_tables::L1_LOW
    } else {
        precomputed_tables::L1_FULL
    };
    let precomputed_tables = precomputed_tables::read_or_generate_precomputed_tables(
        precomputed_tables_path.as_deref(),
        precomputed_tables_size,
        LogProgressTableGenerationReportFunction,
        true,
    )
    .await?;
    let xelis_wallet = Wallet::open(&name, &password, network, precomputed_tables)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
        pending_transactions: RwLock::new(HashMap::new()),
    })
}

impl XelisWallet {
    // Change the wallet password
    pub async fn change_password(&self, old_password: String, new_password: String) -> Result<()> {
        self.wallet.set_password(&old_password, &new_password).await
    }

    // set the wallet to online mode
    pub async fn online_mode(&self, daemon_address: String) -> Result<()> {
        Ok(self.wallet.set_online_mode(&daemon_address, true).await?)
    }

    // set the wallet to offline mode
    pub async fn offline_mode(&self) -> Result<()> {
        Ok(self.wallet.set_offline_mode().await?)
    }

    // Check if the wallet is online
    pub async fn is_online(&self) -> bool {
        self.wallet.is_online().await
    }

    // Get the wallet address as a string
    #[frb(sync)]
    pub fn get_address_str(&self) -> String {
        self.wallet.get_address().to_string()
    }

    // get the wallet network
    #[frb(sync)]
    pub fn get_network(&self) -> String {
        self.wallet.get_network().to_string()
    }

    // close securely the wallet
    pub async fn close(&self) {
        self.wallet.close().await;
    }

    // get the wallet mnemonic seed in different languages
    pub async fn get_seed(&self, language_index: Option<usize>) -> Result<String> {
        let index = language_index.unwrap_or_default();
        self.wallet.get_seed(index)
    }

    // get the wallet nonce
    pub async fn get_nonce(&self) -> u64 {
        self.wallet.get_nonce().await
    }

    // check if the password is valid
    pub async fn is_valid_password(&self, password: String) -> Result<()> {
        self.wallet.is_valid_password(&password).await
    }

    // check if the wallet has a Xelis balance
    pub async fn has_xelis_balance(&self) -> Result<bool> {
        let storage = self.wallet.get_storage().read().await;
        storage.has_balance_for(&XELIS_ASSET).await
    }

    // get the wallet Xelis balance
    pub async fn get_xelis_balance(&self) -> Result<String> {
        let storage = self.wallet.get_storage().read().await;
        let balance = storage
            .get_plaintext_balance_for(&XELIS_ASSET)
            .await
            .unwrap_or(0);
        Ok(format_xelis(balance))
    }

    // get all the assets balances (atomic units) in a HashMap
    pub async fn get_asset_balances(&self) -> Result<HashMap<String, String>> {
        let storage = self.wallet.get_storage().read().await;
        let mut balances = HashMap::new();

        for (asset, data) in storage.get_assets_with_data().await? {
            let balance = storage.get_balance_for(&asset).await?;
            balances.insert(
                asset.to_string(),
                format_coin(balance.amount, data.get_decimals()),
            );
        }

        Ok(balances)
    }

    // get the number of decimals of an asset
    pub async fn get_asset_decimals(&self, asset: String) -> Result<u8> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let storage = self.wallet.get_storage().read().await;
        let asset = storage
            .get_asset(&asset_hash)
            .await
            .context("Asset not found in storage")?;
        Ok(asset.get_decimals())
    }

    // rescan the wallet history from a specific height
    pub async fn rescan(&self, topoheight: u64) -> Result<()> {
        Ok(self.wallet.rescan(topoheight, true).await?)
    }

    // estimate the fees for a transaction
    pub async fn estimate_fees(&self, transfers: Vec<Transfer>) -> Result<String> {
        let transaction_type_builder = self
            .create_transfers(transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let estimated_fees = self
            .wallet
            .estimate_fees(transaction_type_builder)
            .await
            .context("Error while estimating fees")?;

        Ok(format_coin(estimated_fees, COIN_DECIMALS))
    }

    // create a transfer transaction
    pub async fn create_transfers_transaction(&self, transfers: Vec<Transfer>) -> Result<String> {
        self.pending_transactions.write().clear();

        info!("Building transaction...");

        let transaction_type_builder = self
            .create_transfers(transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
                    FeeBuilder::default(),
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    // create a transfer all transaction
    pub async fn create_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
    ) -> Result<String> {
        self.pending_transactions.write().clear();

        info!("Building transfer all transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let mut amount = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        let address = Address::from_string(&str_address).context("Invalid address")?;

        let extra_data = match extra_data {
            None => None,
            Some(value) => Some(DataElement::Value(DataValue::String(value))),
        };

        let transfer = TransferBuilder {
            destination: address.clone(),
            amount,
            asset: asset.clone(),
            extra_data: extra_data.clone(),
        };

        let estimated_fees = self
            .wallet
            .estimate_fees(TransactionTypeBuilder::Transfers(vec![transfer]))
            .await
            .context("Error while estimating fees")?;

        if asset == XELIS_ASSET {
            amount = amount
                .checked_sub(estimated_fees)
                .context("Insufficient balance for fees")?;
        }

        let transfer = TransferBuilder {
            destination: address,
            amount,
            asset: asset.clone(),
            extra_data,
        };

        let transaction_type_builder = TransactionTypeBuilder::Transfers(vec![transfer]);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
                    FeeBuilder::default(),
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    // create a burn transaction
    pub async fn create_burn_transaction(
        &self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        self.pending_transactions.write().clear();

        info!("Building burn transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (amount, decimals) = {
            let storage = self.wallet.get_storage().read().await;
            let decimals = storage
                .get_asset(&asset)
                .await
                .context("Asset not found in storage")?
                .get_decimals();
            let amount: u64 = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;
            (amount, decimals)
        };

        info!("Burning {} of {}", format_coin(amount, decimals), asset);

        let payload = BurnPayload {
            amount,
            asset: asset.clone(),
        };

        let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
                    FeeBuilder::Multiplier(1f64),
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    // create a burn all transaction for a specific asset
    pub async fn create_burn_all_transaction(&self, asset_hash: String) -> Result<String> {
        self.pending_transactions.write().clear();

        info!("Building burn all transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let mut amount = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        info!("Burning all {} of {}", amount, asset);

        let mut payload = BurnPayload {
            amount,
            asset: asset.clone(),
        };

        let estimated_fees = self
            .wallet
            .estimate_fees(TransactionTypeBuilder::Burn(payload.clone()))
            .await
            .context("Error while estimating fees")?;

        if asset == XELIS_ASSET {
            amount -= estimated_fees;
            payload.amount = amount;
        }

        let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
                    FeeBuilder::default(),
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    // clear a pending transaction
    pub fn clear_transaction(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        let hash = Hash::from_hex(&tx_hash)?;
        let res = self
            .pending_transactions
            .write()
            .remove(&hash)
            .context("Cannot delete pending transaction");
        info!("tx: {} removed from pending transaction", hash);
        res
    }

    // broadcast a transaction to the network
    pub async fn broadcast_transaction(&self, tx_hash: String) -> Result<()> {
        info!("start to broadcast tx: {}", tx_hash);

        if self.wallet.is_online().await {
            let (tx, mut state) = self.clear_transaction(tx_hash.clone())?;
            let mut storage = self.wallet.get_storage().write().await;

            info!("Broadcasting transaction...");
            if let Err(e) = self.wallet.submit_transaction(&tx).await {
                error!("Error while submitting transaction, clearing cache...");
                storage.clear_tx_cache();
                storage.delete_unconfirmed_balances().await;

                warn!("Inserting back to pending transactions in case of retry...");
                let hash: Hash = Hash::from_hex(&tx_hash)?;
                self.pending_transactions.write().insert(hash, (tx, state));

                bail!(e)
            } else {
                info!("Transaction submitted successfully!");
                state.apply_changes(&mut storage).await?;
                info!("Transaction applied to storage");
            }
        } else {
            return Err(anyhow!(
                "Wallet is offline, transaction cannot be submitted"
            ));
        }

        Ok(())
    }

    // get all the transactions history
    pub async fn all_history(&self) -> Result<Vec<String>> {
        let mut txs: Vec<String> = Vec::new();

        let storage = self.wallet.get_storage().read().await;
        let mut transactions = storage.get_transactions()?;

        if transactions.is_empty() {
            info!("No transactions available");
            return Ok(txs);
        }

        // desc ordered
        transactions.sort_by(|a, b| b.get_topoheight().cmp(&a.get_topoheight()));

        for tx in transactions.into_iter() {
            let transaction_entry = tx.serializable(self.wallet.get_network().is_mainnet());
            let json_tx = serde_json::to_string(&transaction_entry)?;
            txs.push(json_tx);
        }

        Ok(txs)
    }

    // Redirect events from wallet to a dart stream
    pub async fn events_stream(&self, sink: StreamSink<String>) {
        let mut rx = self.wallet.subscribe_events().await;

        loop {
            let result = rx.recv().await;
            match result {
                Ok(event) => {
                    let json_event = json!({"event": event.kind(), "data": event}).to_string();
                    sink.add(json_event)
                        .expect("Unable to send event data through stream");
                }
                Err(e) => {
                    debug!("Error with events stream: {}", e);
                    break;
                }
            }
        }
    }

    // Get daemon info (network, version, etc)
    pub async fn get_daemon_info(&self) -> Result<String> {
        let network_handler = self.wallet.get_network_handler().lock().await;
        if let Some(handler) = network_handler.as_ref() {
            let api = handler.get_api();

            let info = match api.get_info().await {
                Ok(info) => info,
                Err(e) => {
                    return Err(e);
                }
            };

            Ok(serde_json::to_string(&info)?)
        } else {
            Err(anyhow!("network handler not available"))
        }
    }

    // Format amount to human readable format
    pub async fn format_coin(
        &self,
        atomic_amount: u64,
        asset_hash: Option<String>,
    ) -> Result<String> {
        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let decimals = {
            let storage = self.wallet.get_storage().read().await;
            let asset = storage
                .get_asset(&asset)
                .await
                .context("Asset not found in storage")?;
            asset.get_decimals()
        };

        Ok(format_coin(atomic_amount, decimals))
    }

    // Export transactions to a CSV file
    pub async fn export_transactions_to_csv_file(&self, file_path: String) -> Result<()> {
        let path = Path::new(&file_path);
        let storage = self.wallet.get_storage().read().await;
        let transactions = storage.get_transactions()?;
        if transactions.is_empty() {
            return Err(anyhow!("No transactions to export"));
        }
        let mut file = File::create(&path).context("Error while creating CSV file")?;
        self.wallet
            .export_transactions_in_csv(&storage, transactions, &mut file)
            .await
            .context("Error while exporting transactions to CSV")?;
        Ok(())
    }

    pub async fn convert_transactions_to_csv(&self) -> Result<String> {
        let storage = self.wallet.get_storage().read().await;
        let transactions = storage.get_transactions()?;
        if transactions.is_empty() {
            return Err(anyhow!("No transactions to export"));
        }
        let mut csv = Vec::new();
        self.wallet
            .export_transactions_in_csv(&storage, transactions, &mut csv)
            .await
            .context("Error while exporting transactions to CSV")?;
        Ok(String::from_utf8(csv).context("Error while converting CSV to string")?)
    }

    // Private method to create TransactionTypeBuilder from transfers
    async fn create_transfers(&self, transfers: Vec<Transfer>) -> Result<TransactionTypeBuilder> {
        let mut vec = Vec::new();

        for transfer in transfers {
            let asset = Hash::from_hex(&transfer.asset_hash).context("Invalid asset")?;

            let amount = self
                .convert_float_amount(transfer.float_amount, &asset)
                .await
                .context("Error while converting amount to atomic format")?;

            let address = Address::from_string(&transfer.str_address).context("Invalid address")?;

            let transfer_builder = TransferBuilder {
                destination: address,
                amount,
                asset,
                extra_data: match transfer.extra_data {
                    None => None,
                    Some(value) => Some(DataElement::Value(DataValue::String(value))),
                },
            };

            vec.push(transfer_builder);
        }

        Ok(TransactionTypeBuilder::Transfers(vec))
    }

    // Private method to convert float amount to atomic format
    async fn convert_float_amount(&self, float_amount: f64, asset: &Hash) -> Result<u64> {
        let storage = self.wallet.get_storage().read().await;
        let decimals = storage.get_asset(&asset).await?.get_decimals();
        let amount = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;
        Ok(amount)
    }
}
