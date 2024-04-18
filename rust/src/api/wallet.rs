use std::collections::HashMap;
use std::ops::ControlFlow;
use std::path::Path;
use std::sync::{Arc, Mutex};

use anyhow::{anyhow, Context, Result};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use log::{debug, info};
use serde::{Deserialize, Serialize};
use serde_json::json;
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{ecdlp, Address, Hash, Hashable};
pub use xelis_common::network::Network;
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{FeeBuilder, TransactionTypeBuilder, TransferBuilder};
use xelis_common::transaction::BurnPayload;
pub use xelis_common::transaction::Transaction;
use xelis_common::utils::{format_coin, format_xelis};
pub use xelis_wallet::transaction_builder::TransactionBuilderState;
use xelis_wallet::wallet::{Wallet, PRECOMPUTED_TABLES_L1};

use crate::api::progress_report::{add_progress_report, Report};
use crate::frb_generated::StreamSink;

#[frb(mirror(Network))]
pub enum _Network {
    Mainnet,
    Testnet,
    Dev,
}

struct LogProgressTableGenerationReportFunction;

impl ecdlp::ProgressTableGenerationReportFunction for LogProgressTableGenerationReportFunction {
    fn report(&self, progress: f64, step: ecdlp::ReportStep) -> ControlFlow<()> {
        let step_str = format!("{:?}", step);
        add_progress_report(Report::TableGeneration {
            progress,
            step: step_str,
            message: None,
        });
        debug!("Progress: {:.2}% on step {:?}", progress * 100.0, step);

        ControlFlow::Continue(())
    }
}

#[frb(sync)]
pub fn precomputed_tables_exist(precomputed_tables_path: String) -> bool {
    let file_path =
        format!("{precomputed_tables_path}precomputed_tables_{PRECOMPUTED_TABLES_L1}.bin");
    return Path::new(&file_path).is_file();
}

pub struct XelisWallet {
    wallet: Arc<Wallet>,
}

lazy_static! {
    pub static ref PENDING_TRANSACTIONS: Mutex<HashMap<Hash, (Transaction, TransactionBuilderState)>> =
        Mutex::new(HashMap::new());
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

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SummaryTransaction {
    hash: String,
    amount: u64,
    fee: u64,
    transaction_type: TransactionTypeBuilder,
}

impl XelisWallet {
    pub async fn change_password(&self, old_password: String, new_password: String) -> Result<()> {
        self.wallet.set_password(old_password, new_password).await
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
        Ok(self.wallet.rescan(topoheight).await?)
    }

    pub async fn create_transfer_transaction(
        &self,
        float_amount: f64,
        str_address: String,
        asset_hash: Option<String>,
    ) -> Result<String> {
        let address = Address::from_string(&str_address).context("Invalid address")?;
        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(value).unwrap_or(XELIS_ASSET),
        };
        let mut storage = self.wallet.get_storage().write().await;
        let decimals = storage.get_asset_decimals(&asset).unwrap_or(COIN_DECIMALS);
        let amount = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;

        info!(
            "Sending {} of {} to {}",
            format_coin(amount, decimals),
            asset,
            address.to_string()
        );

        info!("Building transaction...");

        let transfer = TransferBuilder {
            destination: address,
            amount,
            asset,
            extra_data: None,
        };

        let transaction_type_builder = TransactionTypeBuilder::Transfers(vec![transfer]);

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
            .lock()
            .unwrap()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            amount,
            fee,
            transaction_type: transaction_type_builder
        })
            .to_string())
    }

    pub async fn create_burn_transaction(
        &mut self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        let asset = Hash::from_hex(asset_hash)?;
        let mut storage = self.wallet.get_storage().write().await;
        let decimals = storage.get_asset_decimals(&asset).unwrap_or(COIN_DECIMALS);
        let amount = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;

        info!("Burning {} of {}", format_coin(amount, decimals), asset);

        let payload = BurnPayload { amount, asset };
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
            .lock()
            .unwrap()
            .insert(hash.clone(), (tx, state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            amount,
            fee,
            transaction_type: transaction_type_builder
        })
            .to_string())
    }

    #[frb(sync)]
    pub fn cancel_transaction(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        let hash = Hash::from_hex(tx_hash).unwrap();
        Ok(PENDING_TRANSACTIONS
            .lock()
            .unwrap()
            .remove(&hash)
            .expect("Cannot delete pending transaction"))
    }

    pub async fn broadcast_transaction(&self, tx_hash: String) -> Result<()> {
        let (tx, mut state) = self.cancel_transaction(tx_hash)?;
        let mut storage = self.wallet.get_storage().write().await;

        if self.wallet.is_online().await {
            self.wallet.submit_transaction(&tx).await?;
            state.apply_changes(&mut storage).await?;

            info!("Transaction submitted successfully!");
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

    pub async fn online_mode(&self, daemon_address: String) -> Result<()> {
        Ok(self.wallet.set_online_mode(&daemon_address).await?)
    }

    pub async fn offline_mode(&self) -> Result<()> {
        Ok(self.wallet.set_offline_mode().await?)
    }

    pub async fn is_online(&self) -> bool {
        self.wallet.is_online().await
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
}
