use anyhow::{anyhow, Context, Result};
use std::collections::HashMap;
use std::sync::Arc;
use std::thread::sleep;
use std::time::Duration;

use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use log::{debug, info};
use serde_json::json;
use xelis_common::api::wallet::FeeBuilder;
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::address::{Address, AddressType};
use xelis_common::crypto::hash::{Hash, Hashable};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::TransactionType;
use xelis_common::utils::{format_coin, format_xelis, get_network};
use xelis_wallet::wallet::Wallet;

#[frb(opaque)]
pub struct XelisWallet {
    wallet: Arc<Wallet>,
}

pub fn create_xelis_wallet(
    name: String,
    password: String,
    seed: Option<String>,
) -> Result<XelisWallet> {
    let network = get_network();
    let xelis_wallet = Wallet::create(name, password, seed, network)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
    })
}

pub fn open_xelis_wallet(name: String, password: String) -> Result<XelisWallet> {
    let network = get_network();
    let xelis_wallet = Wallet::open(name, password, network)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
    })
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

    pub async fn get_seed(
        &self,
        password: String,
        language_index: Option<usize>,
    ) -> Result<String> {
        self.wallet.is_valid_password(password).await?;
        let index = language_index.unwrap_or_default();
        self.wallet.get_seed(index)
    }

    pub async fn get_nonce(&self) -> u64 {
        self.wallet.get_nonce().await
    }

    pub async fn get_xelis_balance(&self) -> String {
        let storage = self.wallet.get_storage().read().await;
        let balance = storage.get_balance_for(&XELIS_ASSET).unwrap_or_default();
        format_xelis(balance)
    }

    pub async fn get_asset_balances(&self) -> Result<HashMap<String, String>> {
        let storage = self.wallet.get_storage().read().await;
        let mut balances = HashMap::new();

        for (asset, decimals) in storage.get_assets_with_decimals()? {
            let balance = storage.get_balance_for(&asset).unwrap_or(0);
            balances.insert(asset.to_string(), format_coin(balance, decimals));
        }

        Ok(balances)
    }

    pub async fn rescan(&self, topoheight: u64) -> Result<()> {
        Ok(self.wallet.rescan(topoheight).await?)
    }

    pub async fn transfer(
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

        let (_max_balance, decimals) = {
            let storage = self.wallet.get_storage().read().await;
            let balance = storage.get_balance_for(&asset).unwrap_or(0);
            let decimals = storage.get_asset_decimals(&asset).unwrap_or(COIN_DECIMALS);
            (balance, decimals)
        };

        let amount = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;
        info!(
            "Sending {} of {} to {}",
            format_coin(amount, decimals),
            asset,
            address.to_string()
        );

        info!("Building transaction...");
        let (key, address_type) = address.split();
        let extra_data = match address_type {
            AddressType::Normal => None,
            AddressType::Data(data) => Some(data),
        };

        let tx = {
            let storage = self.wallet.get_storage().read().await;
            let transfer = self
                .wallet
                .create_transfer(&storage, asset, key, extra_data, amount)
                .context("Error while creating transfer")?;
            self.wallet
                .create_transaction(
                    &storage,
                    TransactionType::Transfer(vec![transfer]),
                    FeeBuilder::default(),
                )
                .context("Error while creating transaction")?
        };

        if self.wallet.is_online().await {
            self.wallet.submit_transaction(&tx).await?;
            info!("Transaction submitted successfully!");
        } else {
            return Err(anyhow!(
                "Wallet is offline, transaction cannot be submitted"
            ));
        }

        // TODO: send the entire tx struct to the dart side
        Ok(tx.hash().to_hex())
    }

    // TODO: Burn fct

    const TXS_PER_PAGE: usize = 10;
    pub async fn history(&self, requested_page: Option<usize>) -> Result<Vec<String>> {
        let page = requested_page.unwrap_or(1);
        let mut txs: Vec<String> = Vec::new();

        let storage = self.wallet.get_storage().read().await;
        let mut transactions = storage.get_transactions()?;

        if transactions.is_empty() {
            info!("No transactions available");
            return Ok(txs);
        }

        // desc ordered
        transactions.sort_by(|a, b| b.get_topoheight().cmp(&a.get_topoheight()));
        let mut max_pages = transactions.len() / XelisWallet::TXS_PER_PAGE;
        if transactions.len() % XelisWallet::TXS_PER_PAGE != 0 {
            max_pages += 1;
        }

        if page > max_pages {
            return Err(anyhow!(
                "Page must be less than maximum pages ({})",
                max_pages - 1
            ));
        }

        info!(
            "Transactions (total {}) page {}/{}:",
            transactions.len(),
            page,
            max_pages
        );

        for tx in transactions
            .iter()
            .skip((page - 1) * XelisWallet::TXS_PER_PAGE)
            .take(XelisWallet::TXS_PER_PAGE)
        {
            info!("- {}", tx);
            let json_tx = serde_json::to_string(tx).expect("Tx serialization failed");
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

    const FIVE_SECONDS: Duration = Duration::from_secs(5);
    pub async fn daemon_info_stream(&self, sink: StreamSink<String>) {
        loop {
            let mutex = self.wallet.get_network_handler().await;
            let lock = mutex.lock().await;

            match lock.as_ref() {
                None => {
                    break;
                }
                Some(network_handler) => {
                    let api = network_handler.get_api();

                    let info = match api.get_info().await {
                        Ok(info) => info,
                        Err(e) => {
                            debug!("Impossible to call get_info RPC method: {}", e);
                            break;
                        }
                    };

                    let json_info =
                        serde_json::to_string(&info).expect("GetInfoResult serialization failed");

                    sink.add(json_info)
                        .expect("Unable to send GetInfoResult through stream");
                }
            }
            sleep(XelisWallet::FIVE_SECONDS);
        }
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
