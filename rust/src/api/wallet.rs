use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{anyhow, Context, Result};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use log::{debug, info};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use serde_json::json;
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{Address, Hash, Hashable};
use xelis_common::network::Network;
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{FeeBuilder, TransactionTypeBuilder, TransferBuilder};
use xelis_common::transaction::BurnPayload;
pub use xelis_common::transaction::Transaction;
use xelis_common::utils::{format_coin, format_xelis};
pub use xelis_wallet::transaction_builder::TransactionBuilderState;
use xelis_wallet::wallet::Wallet;

use crate::api::table_generation::LogProgressTableGenerationReportFunction;
use crate::frb_generated::StreamSink;

lazy_static! {
    pub static ref PENDING_TRANSACTIONS: RwLock<HashMap<Hash, (Transaction, TransactionBuilderState)>> =
        RwLock::new(HashMap::new());
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SummaryTransaction {
    hash: String,
    // amount: u64,
    amounts: HashMap<String, u64>,
    fee: u64,
    transaction_type: TransactionTypeBuilder,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Transfer {
    pub float_amount: f64,
    pub str_address: String,
    pub asset_hash: Option<String>,
}

pub struct XelisWallet {
    wallet: Arc<Wallet>,
}

pub fn create_xelis_wallet(
    name: String,
    password: String,
    network: Network,
    seed: Option<String>,
    precomputed_tables_path: Option<String>,
) -> Result<XelisWallet> {
    let precomputed_tables = Wallet::read_or_generate_precomputed_tables(
        precomputed_tables_path,
        LogProgressTableGenerationReportFunction,
    )?;
    let xelis_wallet = Wallet::create(name, password, seed, network, precomputed_tables)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
    })
}

pub fn open_xelis_wallet(
    name: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
) -> Result<XelisWallet> {
    let precomputed_tables = Wallet::read_or_generate_precomputed_tables(
        precomputed_tables_path,
        LogProgressTableGenerationReportFunction,
    )?;
    let xelis_wallet = Wallet::open(name, password, network, precomputed_tables)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
    })
}

impl XelisWallet {
    pub async fn change_password(&self, old_password: String, new_password: String) -> Result<()> {
        self.wallet.set_password(old_password, new_password).await
    }

    pub async fn online_mode(&self, daemon_address: String) -> Result<()> {
        Ok(self.wallet.set_online_mode(&daemon_address, true).await?)
    }

    pub async fn offline_mode(&self) -> Result<()> {
        Ok(self.wallet.set_offline_mode().await?)
    }

    pub async fn is_online(&self) -> bool {
        self.wallet.is_online().await
    }

    #[frb(sync)]
    pub fn get_address_str(&self) -> String {
        self.wallet.get_address().to_string()
    }

    #[frb(sync)]
    pub fn get_network(&self) -> String {
        self.wallet.get_network().to_string()
    }

    pub async fn close(&self) {
        self.wallet.close().await;
    }

    pub async fn get_seed(&self, language_index: Option<usize>) -> Result<String> {
        let index = language_index.unwrap_or_default();
        self.wallet.get_seed(index)
    }

    pub async fn get_nonce(&self) -> u64 {
        self.wallet.get_nonce().await
    }

    pub async fn is_valid_password(&self, password: String) -> Result<()> {
        self.wallet.is_valid_password(password).await
    }

    pub async fn has_xelis_balance(&self) -> Result<bool> {
        let storage = self.wallet.get_storage().read().await;
        storage.has_balance_for(&XELIS_ASSET).await
    }

    pub async fn get_xelis_balance(&self) -> Result<String> {
        let storage = self.wallet.get_storage().read().await;
        let balance = storage.get_balance_for(&XELIS_ASSET).await?;
        Ok(format_xelis(balance.amount))
    }

    pub async fn get_asset_balances(&self) -> Result<HashMap<String, String>> {
        let storage = self.wallet.get_storage().read().await;
        let mut balances = HashMap::new();

        for (asset, decimals) in storage.get_assets_with_decimals().await? {
            let balance = storage.get_balance_for(&asset).await?;
            balances.insert(asset.to_string(), format_coin(balance.amount, decimals));
        }

        Ok(balances)
    }

    pub async fn rescan(&self, topoheight: u64) -> Result<()> {
        Ok(self.wallet.rescan(topoheight, true).await?)
    }

    pub async fn estimate_fees(&self, transfers: Vec<Transfer>) -> Result<u64> {
        let transaction_type_builder = self
            .create_transfers(transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let estimated_fees = self
            .wallet
            .estimate_fees(transaction_type_builder)
            .await
            .context("Error while estimating fees")?;

        Ok(estimated_fees)
    }

    pub async fn create_transfers_transaction(&self, transfers: Vec<Transfer>) -> Result<String> {
        PENDING_TRANSACTIONS.write().clear();

        info!("Building transaction...");

        let amounts = self
            .compute_total_amounts(transfers.clone())
            .await
            .context("Error while computed total amounts")?;

        let transaction_type_builder = self
            .create_transfers(transfers)
            .await
            .context("Error while creating transaction type builder")?;
        let mut storage = self.wallet.get_storage().write().await;

        let (state, tx) = self
            .wallet
            .create_transaction_with_storage(
                &mut storage,
                transaction_type_builder.clone(),
                FeeBuilder::default(),
            )
            .await?;

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        PENDING_TRANSACTIONS
            .write()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            amounts,
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
    ) -> Result<String> {
        PENDING_TRANSACTIONS.write().clear();

        info!("Building transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(value).unwrap_or(XELIS_ASSET),
        };

        let amount = {
            let storage = self.wallet.get_storage().read().await;
            let amount = storage.get_plaintext_balance_for(&asset).await.unwrap_or(0);
            amount
        };

        let address = Address::from_string(&str_address).context("Invalid address")?;

        let transfers = self
            .create_transfer_with_fees_included(amount, address, asset.clone())
            .await?;

        let mut storage = self.wallet.get_storage().write().await;
        let (state, tx) = self
            .wallet
            .create_transaction_with_storage(&mut storage, transfers.clone(), FeeBuilder::default())
            .await?;

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        PENDING_TRANSACTIONS
            .write()
            .insert(hash.clone(), (tx, state));

        let amounts = HashMap::from([(asset.to_hex(), amount)]);

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            amounts,
            fee,
            transaction_type: transfers
        })
        .to_string())
    }

    pub async fn create_burn_transaction(
        &mut self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        PENDING_TRANSACTIONS.write().clear();

        info!("Building transaction...");

        let asset = Hash::from_hex(asset_hash)?;
        let mut storage = self.wallet.get_storage().write().await;
        let decimals = storage.get_asset_decimals(&asset).unwrap_or(COIN_DECIMALS);
        let amount = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;

        info!("Burning {} of {}", format_coin(amount, decimals), asset);

        let payload = BurnPayload {
            amount,
            asset: asset.clone(),
        };
        let transaction_type_builder = TransactionTypeBuilder::Burn(payload);
        let (state, tx) = self
            .wallet
            .create_transaction_with_storage(
                &mut storage,
                transaction_type_builder.clone(),
                FeeBuilder::Multiplier(1f64),
            )
            .await?;

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        PENDING_TRANSACTIONS
            .write()
            .insert(hash.clone(), (tx, state));

        let amounts = HashMap::from([(asset.to_hex(), amount)]);

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            amounts,
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub fn clear_transaction(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        let hash = Hash::from_hex(tx_hash.clone()).unwrap();
        let res = PENDING_TRANSACTIONS
            .write()
            .remove(&hash)
            .expect("Cannot delete pending transaction");
        info!("tx: {} removed from pending transaction", tx_hash);
        Ok(res)
    }

    pub async fn broadcast_transaction(&self, tx_hash: String) -> Result<()> {
        let (tx, mut state) = self.clear_transaction(tx_hash)?;
        let mut storage = self.wallet.get_storage().write().await;
        state.apply_changes(&mut storage).await?;

        if self.wallet.is_online().await {
            if let Err(_e) = self.wallet.submit_transaction(&tx).await {
                let mut storage = self.wallet.get_storage().write().await;
                storage.clear_tx_cache();
                storage.delete_unconfirmed_balances().await;
            } else {
                info!("Transaction submitted successfully!");
            }
        } else {
            return Err(anyhow!(
                "Wallet is offline, transaction cannot be submitted"
            ));
        }
        Ok(())
    }

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
            let json_tx =
                serde_json::to_string(&transaction_entry).expect("Tx serialization failed");
            txs.push(json_tx);
        }

        Ok(txs)
    }

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

    pub async fn get_daemon_info(&self) -> Result<String> {
        let mutex = self.wallet.get_network_handler().await;
        let lock = mutex.lock().await;
        let network_handler = lock.as_ref().context("network handler not available")?;
        let api = network_handler.get_api();

        let info = match api.get_info().await {
            Ok(info) => info,
            Err(e) => {
                return Err(e);
            }
        };

        Ok(serde_json::to_string(&info).expect("GetInfoResult serialization failed"))
    }

    pub async fn format_coin(
        &self,
        atomic_amount: u64,
        asset_hash: Option<String>,
    ) -> Result<String> {
        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(value).unwrap_or(XELIS_ASSET),
        };

        let decimals = {
            let storage = self.wallet.get_storage().read().await;
            let decimals = storage.get_asset_decimals(&asset).unwrap_or(COIN_DECIMALS);
            decimals
        };

        Ok(format_coin(atomic_amount, decimals))
    }

    async fn create_transfers(&self, transfers: Vec<Transfer>) -> Result<TransactionTypeBuilder> {
        let mut vec = Vec::new();

        for transfer in transfers {
            let asset = match transfer.asset_hash {
                None => XELIS_ASSET,
                Some(value) => Hash::from_hex(value).unwrap_or(XELIS_ASSET),
            };

            let amount = self
                .convert_float_amount(transfer.float_amount, asset.clone())
                .await
                .context("Error while converting amount to atomic format")?;

            let address = Address::from_string(&transfer.str_address).context("Invalid address")?;

            let transfer_builder = TransferBuilder {
                destination: address,
                amount,
                asset,
                extra_data: None,
            };

            vec.push(transfer_builder);
        }

        Ok(TransactionTypeBuilder::Transfers(vec))
    }

    async fn create_transfer_with_fees_included(
        &self,
        mut amount: u64,
        address: Address,
        asset: Hash,
    ) -> Result<TransactionTypeBuilder> {
        let transfer = TransferBuilder {
            destination: address.clone(),
            amount,
            asset: asset.clone(),
            extra_data: None,
        };

        let estimated_fees = self
            .wallet
            .estimate_fees(TransactionTypeBuilder::Transfers(vec![transfer]))
            .await
            .context("Error while estimating fees")?;

        if asset == XELIS_ASSET {
            amount -= estimated_fees;
        }

        let transfer = TransferBuilder {
            destination: address,
            amount,
            asset: asset.clone(),
            extra_data: None,
        };

        Ok(TransactionTypeBuilder::Transfers(vec![transfer]))
    }

    async fn convert_float_amount(&self, float_amount: f64, asset: Hash) -> Result<u64> {
        let storage = self.wallet.get_storage().read().await;
        let decimals = storage.get_asset_decimals(&asset).unwrap_or(COIN_DECIMALS);
        let amount = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;
        Ok(amount)
    }

    async fn compute_total_amounts(
        &self,
        transfers: Vec<Transfer>,
    ) -> Result<HashMap<String, u64>> {
        let mut amounts: HashMap<String, u64> = HashMap::new();

        for transfer in transfers {
            let asset_hash = match transfer.asset_hash.clone() {
                None => XELIS_ASSET,
                Some(value) => Hash::from_hex(value).unwrap_or(XELIS_ASSET),
            };

            let amount = self
                .convert_float_amount(transfer.float_amount, asset_hash)
                .await
                .context("Error while converting amount to atomic format")?;

            let asset_hex = transfer.asset_hash.unwrap_or_else(|| XELIS_ASSET.to_hex());

            match amounts.get(&asset_hex) {
                None => {
                    amounts.insert(asset_hex, amount);
                }
                Some(value) => {
                    amounts.insert(asset_hex, amount + value);
                }
            }
        }

        Ok(amounts)
    }
}
