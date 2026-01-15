use flutter_rust_bridge::frb;

use std::collections::HashMap;
use std::fs::File;
use std::path::Path;
use std::sync::Arc;
use std::thread;

use anyhow::{anyhow, bail, Context, Result};
use indexmap::IndexSet;
use log::{debug, error, info, warn};
use parking_lot::{Mutex, RwLock};
use serde_json::json;
use xelis_common::api::wallet::BaseFeeMode;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::asset::{AssetData, AssetOwner, MaxSupplyMode};
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{Address, Hash, Hashable, Signature};
use xelis_common::network::Network;
use xelis_common::serializer::Serializer;
use xelis_common::tokio::sync::broadcast::error::RecvError;
use xelis_common::transaction::builder::{
    FeeBuilder, MultiSigBuilder, TransactionTypeBuilder, TransferBuilder, UnsignedTransaction,
};
use xelis_common::transaction::multisig::{MultiSig, SignatureId};
use xelis_common::transaction::BurnPayload;
pub use xelis_common::transaction::Transaction;
use xelis_common::utils::{format_coin, format_xelis};
use xelis_wallet::precomputed_tables;
pub use xelis_wallet::precomputed_tables::PrecomputedTablesShared;
pub use xelis_wallet::transaction_builder::TransactionBuilderState;
use xelis_wallet::wallet::{RecoverOption, Wallet};

use super::precomputed_tables::{LogProgressTableGenerationReportFunction, PrecomputedTableType};
use crate::frb_generated::StreamSink;

use super::models::wallet_dtos::{
    HistoryPageFilter, MultisigDartPayload, ParticipantDartPayload, SignatureMultisig,
    SummaryTransaction, Transfer, XelisAssetMetadata, XelisAssetOwner, XelisMaxSupplyMode,
};

pub struct XelisWallet {
    wallet: Arc<Wallet>,
    pending_transactions: RwLock<HashMap<Hash, (Transaction, TransactionBuilderState)>>,
    pending_unsigned: RwLock<
        Option<(
            UnsignedTransaction,
            TransactionBuilderState,
            TransactionTypeBuilder,
        )>,
    >,
}

impl From<MaxSupplyMode> for XelisMaxSupplyMode {
    fn from(v: MaxSupplyMode) -> Self {
        match v {
            MaxSupplyMode::None => Self::None,
            MaxSupplyMode::Fixed(x) => Self::Fixed(x),
            MaxSupplyMode::Mintable(x) => Self::Mintable(x),
        }
    }
}

impl From<&AssetOwner> for XelisAssetOwner {
    fn from(value: &AssetOwner) -> Self {
        match value {
            AssetOwner::None => XelisAssetOwner::None,
            AssetOwner::Creator { contract, id } => XelisAssetOwner::Creator {
                contract: contract.to_hex(),
                id: *id,
            },
            AssetOwner::Owner {
                origin,
                origin_id,
                owner,
            } => XelisAssetOwner::Owner {
                origin: origin.to_hex(),
                origin_id: *origin_id,
                owner: owner.to_hex(),
            },
        }
    }
}

static CACHED_TABLES: Mutex<Option<PrecomputedTablesShared>> = Mutex::new(None);
static MT_PARAMS: Mutex<Option<(usize, usize)>> = Mutex::new(None);

fn get_mt_params() -> (usize, usize) {
    let mut guard = MT_PARAMS.lock();

    if let Some(params) = *guard {
        return params;
    }

    let cpu_cores = thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);

    let thread_count = (cpu_cores.saturating_sub(2)).max(1).min(32);
    let concurrency = thread_count * 4;

    *guard = Some((thread_count, concurrency));
    (thread_count, concurrency)
}

#[frb(sync)]
pub fn refresh_mt_params() {
    *MT_PARAMS.lock() = None;
    let _ = get_mt_params();
}

#[frb(sync)]
pub fn set_mt_params(thread_count: usize, concurrency: usize) {
    *MT_PARAMS.lock() = Some((thread_count, concurrency));
}

#[frb(sync)]
pub fn clear_cached_tables() {
    CACHED_TABLES.lock().take();
}

#[frb(sync)]
pub fn drop_wallet(wallet: XelisWallet) {
    drop(wallet);
}

pub async fn update_tables(
    precomputed_tables_path: String,
    precomputed_table_type: PrecomputedTableType,
) -> Result<()> {
    let precomputed_tables_size = precomputed_table_type.to_l1_size()?;

    let tables = precomputed_tables::read_or_generate_precomputed_tables(
        Some(&precomputed_tables_path),
        precomputed_tables_size,
        LogProgressTableGenerationReportFunction,
        true,
    )
    .await?;

    CACHED_TABLES.lock().replace(tables.clone());
    Ok(())
}

pub fn get_current_precomputed_tables_type() -> Result<PrecomputedTableType> {
    info!("Getting current precomputed tables type...");
    let guard = CACHED_TABLES.lock();
    let tables_arc = guard
        .as_ref()
        .ok_or_else(|| anyhow!("Precomputed tables not initialized"))?;

    info!("Precomputed tables found in cache.");
    let size = {
        let tables_guard = tables_arc
            .read()
            .expect("Failed to read precomputed tables");
        tables_guard.view().get_l1()
    };
    info!("Current precomputed tables L1 size: {}", size);

    let table_type = match size {
        precomputed_tables::L1_LOW => PrecomputedTableType::L1Low,
        precomputed_tables::L1_MEDIUM => PrecomputedTableType::L1Medium,
        precomputed_tables::L1_FULL => PrecomputedTableType::L1Full,
        c => PrecomputedTableType::Custom(c),
    };

    Ok(table_type)
}

pub async fn create_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    seed: Option<String>,
    private_key: Option<String>,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> Result<XelisWallet> {
    // Build full wallet path: <directory>/<name>
    let full_path = if name.is_empty() {
        if directory.is_empty() {
            bail!("Either 'name' or 'directory' must be non-empty");
        }
        directory.clone()
    } else {
        Path::new(&directory)
            .join(&name)
            .to_string_lossy()
            .to_string()
    };

    let precomputed_tables_size = precomputed_table_type.to_l1_size()?;

    info!("Creating wallet at path: {}", full_path);

    // Use cached tables if available, otherwise generate & cache
    let precomputed_tables = {
        let mut maybe_cached = CACHED_TABLES.lock().clone();
        info!("Maybe cached tables: {}", maybe_cached.is_some());
        match maybe_cached {
            Some(tables) => tables,
            None => {
                info!("No cached tables, generating new ones...");
                let tables = precomputed_tables::read_or_generate_precomputed_tables(
                    precomputed_tables_path.as_deref(),
                    precomputed_tables_size,
                    LogProgressTableGenerationReportFunction,
                    true,
                )
                .await?;
                info!("Precomputed tables generated.");

                maybe_cached.replace(tables.clone());
                tables
            }
        }
    };

    // Recover option (seed / private key / none)
    let recover: Option<RecoverOption> = if let Some(seed) = seed.as_deref() {
        Some(RecoverOption::Seed(seed))
    } else if let Some(private_key) = private_key.as_deref() {
        Some(RecoverOption::PrivateKey(private_key))
    } else {
        None
    };

    let (thread_count, concurrency) = get_mt_params();

    let xelis_wallet = Wallet::create(
        &full_path,
        &password,
        recover,
        network,
        precomputed_tables,
        thread_count,
        concurrency,
    )
    .await?;

    Ok(XelisWallet {
        wallet: xelis_wallet,
        pending_transactions: RwLock::new(HashMap::new()),
        pending_unsigned: RwLock::new(None),
    })
}

pub async fn open_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> Result<XelisWallet> {
    // Build full wallet path: <directory>/<name>
    let full_path = if name.is_empty() {
        if directory.is_empty() {
            bail!("Either 'name' or 'directory' must be non-empty");
        }
        directory.clone()
    } else {
        Path::new(&directory)
            .join(&name)
            .to_string_lossy()
            .to_string()
    };

    let precomputed_tables_size = precomputed_table_type.to_l1_size()?;

    let precomputed_tables = {
        let mut maybe_cached = CACHED_TABLES.lock().clone();
        match maybe_cached {
            Some(tables) => tables,
            None => {
                let tables = precomputed_tables::read_or_generate_precomputed_tables(
                    precomputed_tables_path.as_deref(),
                    precomputed_tables_size,
                    LogProgressTableGenerationReportFunction,
                    true,
                )
                .await?;

                maybe_cached.replace(tables.clone());
                tables
            }
        }
    };

    let (thread_count, concurrency) = get_mt_params();

    let xelis_wallet = Wallet::open(
        &full_path,
        &password,
        network,
        precomputed_tables,
        thread_count,
        concurrency,
    )?;

    Ok(XelisWallet {
        wallet: xelis_wallet,
        pending_transactions: RwLock::new(HashMap::new()),
        pending_unsigned: RwLock::new(None),
    })
}

impl XelisWallet {
    #[frb(ignore)]
    pub fn get_wallet(&self) -> &Arc<Wallet> {
        &self.wallet // Return a reference to the private field
    }

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
    pub fn get_network(&self) -> Network {
        self.wallet.get_network().clone()
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

    // check if the wallet has a balance for an asset
    pub async fn has_asset_balance(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let storage = self.wallet.get_storage().read().await;
        storage.has_balance_for(&asset_hash).await
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

    // get all the balances of the tracked assets
    pub async fn get_tracked_balances(&self) -> Result<HashMap<String, String>> {
        info!("Retrieving tracked asset balances from wallet...");
        let storage = self.wallet.get_storage().read().await;

        let mut balances = HashMap::new();

        let count = storage.get_tracked_assets_count()?;
        if count == 0 {
            info!("No tracked assets found");
            return Ok(balances);
        }
        info!("Retrieving {} tracked asset balances from wallet", count);
        let tracked_assets = storage.get_tracked_assets()?;

        for res in tracked_assets {
            match res {
                Ok(asset) => {
                    if let Some(data) = storage.get_optional_asset(&asset).await? {
                        let balance = storage
                            .get_plaintext_balance_for(&asset)
                            .await
                            .context("Error retrieving balance")?;
                        balances.insert(asset.to_hex(), format_coin(balance, data.get_decimals()));
                    } else {
                        warn!("No asset data for {}", asset);
                    }
                }
                Err(e) => {
                    error!("Error retrieving tracked asset: {}", e);
                }
            }
        }

        Ok(balances)
    }

    // get all the assets known by the wallet
    pub async fn get_known_assets(&self) -> Result<HashMap<String, String>> {
        let storage = self.wallet.get_storage().read().await;

        let mut assets = HashMap::new();

        let count = storage.get_untracked_assets_count()?;
        if count == 0 {
            info!("No known assets in wallet");
            return Ok(assets);
        }
        info!("Retrieving {} known assets from wallet", count);

        for res in storage.get_assets_with_data().await? {
            match res {
                Ok((hash, asset_data)) => {
                    info!("Retrieving asset data for asset {}", hash);
                    let supply_mode_dto = XelisMaxSupplyMode::from(asset_data.get_max_supply());
                    let owner_dto = XelisAssetOwner::from(asset_data.get_owner());

                    let dto = XelisAssetMetadata {
                        name: asset_data.get_name().to_string(),
                        ticker: asset_data.get_ticker().to_string(),
                        decimals: asset_data.get_decimals(),
                        max_supply: supply_mode_dto,
                        owner: Some(owner_dto),
                    };

                    let json_str = serde_json::to_string(&dto)?;
                    assets.insert(hash.to_hex(), json_str);
                }
                Err(e) => {
                    error!("Error retrieving asset data: {}", e);
                }
            }
        }

        Ok(assets)
    }

    // track an asset
    pub async fn track_asset(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let result = self
            .wallet
            .track_asset(asset_hash)
            .await
            .context("Error tracking asset")?;
        Ok(result)
    }

    // untrack an asset
    pub async fn untrack_asset(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let result = self
            .wallet
            .untrack_asset(asset_hash)
            .await
            .context("Error tracking asset")?;
        Ok(result)
    }

    async fn get_asset_data(&self, asset_hash: &Hash) -> Result<AssetData> {
        {
            let storage = self.wallet.get_storage().read().await;
            if storage.has_asset(asset_hash).await? {
                return storage.get_asset(asset_hash).await;
            }
        }

        // 3. offline guard
        if !self.wallet.is_online().await {
            return Err(anyhow!(
                "Asset {} not found in wallet storage/cache and wallet is offline",
                asset_hash
            ));
        }

        // 4. daemon
        let asset_data = {
            let network_handler = self.wallet.get_network_handler().lock().await;
            if let Some(handler) = network_handler.as_ref() {
                let api = handler.get_api();
                debug!("Fetching asset {} from daemon", asset_hash);
                let data = api
                    .get_asset(asset_hash)
                    .await
                    .map_err(|e| anyhow!("Failed to fetch asset from daemon: {}", e))?;

                data.inner
            } else {
                return Err(anyhow!("Network handler not available"));
            }
        };

        debug!(
            "Storing fetched asset {} from network, storing it in wallet storage",
            asset_hash
        );

        let mut storage = self.wallet.get_storage().write().await;
        storage
            .add_asset(asset_hash, asset_data.clone())
            .await
            .context("Error storing fetched asset in wallet storage")?;

        debug!("Asset {} stored in wallet storage", asset_hash);

        Ok(asset_data)
    }

    // get the number of decimals of an asset
    pub async fn get_asset_decimals(&self, asset: String) -> Result<u8> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let data = self.get_asset_data(&asset_hash).await?;
        Ok(data.get_decimals())
    }

    pub async fn get_asset_ticker(&self, asset: String) -> Result<String> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let data = self.get_asset_data(&asset_hash).await?;
        Ok(data.get_ticker().to_string())
    }

    pub async fn get_asset_metadata(&self, asset: String) -> Result<String> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let asset_data = self.get_asset_data(&asset_hash).await?;

        let owner_dto = XelisAssetOwner::from(asset_data.get_owner());
        let supply_mode_dto = XelisMaxSupplyMode::from(asset_data.get_max_supply());

        let dto = XelisAssetMetadata {
            name: asset_data.get_name().to_string(),
            ticker: asset_data.get_ticker().to_string(),
            decimals: asset_data.get_decimals(),
            max_supply: supply_mode_dto,
            owner: Some(owner_dto),
        };

        let json_str = serde_json::to_string(&dto)?;
        Ok(json_str)
    }

    pub async fn get_contract_logs(&self, tx_hash: String) -> Result<String> {
        if !self.wallet.is_online().await {
            return Err(anyhow!("Wallet is offline"));
        }

        let hash = Hash::from_hex(&tx_hash).context("Invalid transaction hash")?;

        let network_handler = self.wallet.get_network_handler().lock().await;
        if let Some(handler) = network_handler.as_ref() {
            let api = handler.get_api();
            let result = api
                .get_contract_logs(&hash)
                .await
                .map_err(|e| anyhow!("Failed to fetch contract logs from daemon: {}", e))?;

            let json_str = serde_json::to_string(&result)?;
            Ok(json_str)
        } else {
            Err(anyhow!("Network handler not available"))
        }
    }

    // rescan the wallet history from a specific height
    pub async fn rescan(&self, topoheight: u64) -> Result<()> {
        Ok(self.wallet.rescan(topoheight, true).await?)
    }

    // estimate the fees for a transaction
    pub async fn estimate_fees(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
        let transaction_type_builder = self
            .create_transfers(transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                transaction_type_builder,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        Ok(format_coin(estimated_fees, COIN_DECIMALS))
    }

    // create a transfer transaction
    pub async fn create_transfers_transaction(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
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
                    BaseFeeMode::None,
                    None,
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_multisig_transfers_transaction(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
        info!("Building transaction...");

        let multisig = {
            let storage = self.wallet.get_storage().read().await;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            multisig.cloned()
        };

        match multisig {
            Some(multisig) => {
                let transaction_type_builder = self
                    .create_transfers(transfers)
                    .await
                    .context("Error while creating transaction type builder")?;

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                let hash = unsigned.get_hash_for_multisig().to_hex();

                let mut pending_unsigned = self.pending_unsigned.write();

                *pending_unsigned = Some((unsigned, state, transaction_type_builder));

                info!("Unsigned transaction created: {}", hash);

                Ok(hash)
            }
            None => {
                bail!("No multisig configured");
            }
        }
    }

    // create a transfer all transaction
    pub async fn create_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        // TODO: add extra fee options
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
            encrypt_extra_data: match encrypt_extra_data {
                Some(value) => value,
                None => false,
            },
        };

        let estimated_fees = self
            .wallet
            .estimate_fees(
                TransactionTypeBuilder::Transfers(vec![transfer]),
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
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
            encrypt_extra_data: match encrypt_extra_data {
                Some(value) => value,
                None => false,
            },
        };

        let transaction_type_builder = TransactionTypeBuilder::Transfers(vec![transfer]);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
                    FeeBuilder::default(),
                    BaseFeeMode::None,
                    None,
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_multisig_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        // TODO: add extra fee options
    ) -> Result<String> {
        info!("Building multisig transfer all transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let (mut amount, multisig) = {
            let storage = self.wallet.get_storage().read().await;
            let amount = storage.get_plaintext_balance_for(&asset).await?;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            (amount, multisig.cloned())
        };

        match multisig {
            Some(multisig) => {
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
                    encrypt_extra_data: match encrypt_extra_data {
                        Some(value) => value,
                        None => false,
                    },
                };

                let estimated_fees = self
                    .wallet
                    .estimate_fees(
                        TransactionTypeBuilder::Transfers(vec![transfer]),
                        FeeBuilder::default(),
                        BaseFeeMode::None,
                    )
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
                    encrypt_extra_data: match encrypt_extra_data {
                        Some(value) => value,
                        None => false,
                    },
                };

                let transaction_type_builder = TransactionTypeBuilder::Transfers(vec![transfer]);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                let hash = unsigned.get_hash_for_multisig().to_hex();

                let mut pending_unsigned = self.pending_unsigned.write();

                *pending_unsigned = Some((unsigned, state, transaction_type_builder));

                info!("Unsigned transaction created: {}", hash);

                Ok(hash)
            }
            None => {
                bail!("No multisig configured");
            }
        }
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
                    FeeBuilder::default(),
                    BaseFeeMode::None,
                    None,
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_multisig_burn_transaction(
        &self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        info!("Building burn transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (amount, decimals, multisig) = {
            let storage = self.wallet.get_storage().read().await;
            let decimals = storage
                .get_asset(&asset)
                .await
                .context("Asset not found in storage")?
                .get_decimals();
            let amount: u64 = (float_amount * 10u32.pow(decimals as u32) as f64) as u64;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            (amount, decimals, multisig.cloned())
        };

        match multisig {
            Some(multisig) => {
                info!("Burning {} of {}", format_coin(amount, decimals), asset);

                let payload = BurnPayload {
                    amount,
                    asset: asset.clone(),
                };

                let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                let hash = unsigned.get_hash_for_multisig().to_hex();

                let mut pending_unsigned = self.pending_unsigned.write();

                *pending_unsigned = Some((unsigned, state, transaction_type_builder));

                info!("Unsigned transaction created: {}", hash);

                Ok(hash)
            }
            None => {
                bail!("No multisig configured");
            }
        }
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
            .estimate_fees(
                TransactionTypeBuilder::Burn(payload.clone()),
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
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
                    BaseFeeMode::None,
                    None,
                )
                .await?
        };

        info!("Transaction created!");
        let hash = tx.hash();
        info!("Tx Hash: {}", hash);
        let fee = tx.get_fee();

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    // create a multisig transaction to burn all of an asset
    pub async fn create_multisig_burn_all_transaction(&self, asset_hash: String) -> Result<String> {
        info!("Building burn all transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (mut amount, multisig) = {
            let storage = self.wallet.get_storage().read().await;
            let amount = storage.get_plaintext_balance_for(&asset).await?;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            (amount, multisig.cloned())
        };

        match multisig {
            Some(multisig) => {
                info!("Burning all {} of {}", amount, asset);

                let mut payload = BurnPayload {
                    amount,
                    asset: asset.clone(),
                };

                let estimated_fees = self
                    .wallet
                    .estimate_fees(
                        TransactionTypeBuilder::Burn(payload.clone()),
                        FeeBuilder::default(),
                        BaseFeeMode::None,
                    )
                    .await
                    .context("Error while estimating fees")?;

                if asset == XELIS_ASSET {
                    amount -= estimated_fees;
                    payload.amount = amount;
                }

                let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                let hash = unsigned.get_hash_for_multisig().to_hex();

                let mut pending_unsigned = self.pending_unsigned.write();

                *pending_unsigned = Some((unsigned, state, transaction_type_builder));

                info!("Unsigned transaction created: {}", hash);

                Ok(hash)
            }
            None => {
                bail!("No multisig configured");
            }
        }
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
                storage.clear_tx_cache().await;
                storage.delete_unconfirmed_balances().await;

                warn!("Inserting back to pending transactions in case of retry...");
                let hash: Hash = Hash::from_hex(&tx_hash)?;
                self.pending_transactions.write().insert(hash, (tx, state));

                bail!(e)
            } else {
                info!("Transaction submitted successfully!");
                state
                    .apply_changes(&mut storage)
                    .await
                    .context("Error while applying changes")?;
                info!("Transaction applied to storage");
            }
        } else {
            bail!("Wallet is offline, transaction cannot be submitted");
        }

        Ok(())
    }

    // get the number of transactions in the wallet history
    pub async fn get_history_count(&self) -> Result<usize> {
        let storage = self.wallet.get_storage().read().await;
        Ok(storage.get_transactions_count()?)
    }

    // get all the transactions history
    pub async fn history(&self, filter: HistoryPageFilter) -> Result<Vec<String>> {
        let mut txs: Vec<String> = Vec::new();

        let storage = self.wallet.get_storage().read().await;

        let txs_len = storage.get_transactions_count()?;
        info!("Transactions available: {}", txs_len);
        if txs_len == 0 {
            info!("No transactions available");
            return Ok(txs);
        }

        if let Some(limit) = filter.limit {
            if limit == 0 {
                bail!("Limit cannot be 0");
            }

            let mut max_pages = txs_len / limit;
            if txs_len % limit != 0 {
                max_pages += 1;
            }

            if filter.page > max_pages {
                info!("Page out of range");
                return Ok(txs);
            }
        }

        let address = match filter.address {
            Some(address) => {
                let address = Address::from_string(&address).context("Invalid address")?;
                Some(address.get_public_key().to_owned())
            }
            None => None,
        };

        let asset = match filter.asset_hash {
            Some(asset_hash) => Some(Hash::from_hex(&asset_hash).context("Invalid asset")?),
            None => None,
        };

        let transactions = storage.get_filtered_transactions(
            address.as_ref(),
            asset.as_ref(),
            filter.min_topoheight,
            filter.max_topoheight,
            filter.accept_incoming,
            filter.accept_outgoing,
            match address {
                Some(_) => false,
                None => filter.accept_coinbase,
            },
            match address {
                Some(_) => false,
                None => filter.accept_burn,
            },
            None,
            filter.limit,
            match filter.limit {
                Some(limit) => Some((filter.page - 1) * limit),
                None => None,
            },
        )?;

        for tx in transactions {
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
                Err(RecvError::Lagged(skipped)) => {
                    warn!("Events stream lagged; skipped {} messages", skipped);
                    continue;
                }
                Err(RecvError::Closed) => {
                    error!("Events stream closed; stopping listener");
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
                    bail!("Error while getting daemon info: {}", e);
                }
            };

            Ok(serde_json::to_string(&info)?)
        } else {
            bail!("network handler not available")
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

        let data = self.get_asset_data(&asset).await?;
        Ok(format_coin(atomic_amount, data.get_decimals()))
    }

    // Export transactions to a CSV file
    pub async fn export_transactions_to_csv_file(&self, file_path: String) -> Result<()> {
        let path = Path::new(&file_path);
        let storage = self.wallet.get_storage().read().await;
        let transactions = storage.get_transactions()?;
        if transactions.is_empty() {
            bail!("No transactions to export");
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
            bail!("No transactions to export");
        }
        let mut csv = Vec::new();
        self.wallet
            .export_transactions_in_csv(&storage, transactions, &mut csv)
            .await
            .context("Error while exporting transactions to CSV")?;
        Ok(String::from_utf8(csv).context("Error while converting CSV to string")?)
    }

    // Get multisig state
    pub async fn get_multisig_state(&self) -> Result<Option<String>> {
        let storage = self.wallet.get_storage().read().await;
        let multisig = storage
            .get_multisig_state()
            .await
            .context("Error while reading multisig state")?;
        match multisig {
            Some(multisig) => Ok(Some(
                json!(MultisigDartPayload {
                    threshold: multisig.payload.threshold,
                    participants: multisig
                        .payload
                        .participants
                        .iter()
                        .enumerate()
                        .map(|(i, p)| {
                            ParticipantDartPayload {
                                id: i as u8,
                                address: p
                                    .as_address(self.wallet.get_network().is_mainnet())
                                    .to_string(),
                            }
                        })
                        .collect::<Vec<_>>(),
                    topoheight: multisig.topoheight
                })
                .to_string(),
            )),
            None => Ok(None),
        }
    }

    pub async fn multisig_setup(&self, threshold: u8, participants: Vec<String>) -> Result<String> {
        info!("Setting up multisig...");
        let multisig = {
            let storage = self.wallet.get_storage().read().await;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            multisig.cloned()
        };

        match multisig {
            Some(_multisig) => {
                bail!("Multisig already configured");
            }
            None => {
                let mut participant_addresses = IndexSet::with_capacity(participants.len());
                for participant in participants {
                    let address = Address::from_string(&participant).context("Invalid address")?;
                    participant_addresses.insert(address);
                }

                let payload = MultiSigBuilder {
                    participants: participant_addresses,
                    threshold,
                };
                let transaction_type_builder = TransactionTypeBuilder::MultiSig(payload);

                let (tx, state) = {
                    let mut storage = self.wallet.get_storage().write().await;
                    self.wallet
                        .create_transaction_with_storage(
                            &mut storage,
                            transaction_type_builder.clone(),
                            FeeBuilder::default(),
                            BaseFeeMode::None,
                            None,
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
        }
    }

    #[frb(sync)]
    pub fn is_address_valid_for_multisig(&self, address: String) -> Result<bool> {
        let address = match Address::from_string(&address) {
            Ok(address) => address,
            Err(_) => {
                warn!("Invalid address");
                return Ok(false);
            }
        };

        if !address.is_normal() {
            warn!("Address is not normal");
            return Ok(false);
        }

        let mainnet = self.wallet.get_network().is_mainnet();
        if address.is_mainnet() != mainnet {
            warn!("Address is not from the same network");
            return Ok(false);
        }

        if address.get_public_key() == self.wallet.get_public_key() {
            warn!("Address is the same as the wallet address");
            return Ok(false);
        }

        Ok(true)
    }

    // Initiate the delete multisig process
    pub async fn init_delete_multisig(&self) -> Result<String> {
        info!("Deleting multisig...");
        let multisig = {
            let storage = self.wallet.get_storage().read().await;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            multisig.cloned()
        };

        match multisig {
            Some(multisig) => {
                let payload = MultiSigBuilder {
                    participants: IndexSet::new(),
                    threshold: 0,
                };

                let transaction_type_builder = TransactionTypeBuilder::MultiSig(payload);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                let hash = unsigned.get_hash_for_multisig().to_hex();

                let mut pending_unsigned = self.pending_unsigned.write();

                *pending_unsigned = Some((unsigned, state, transaction_type_builder));

                info!("Unsigned transaction created: {}", hash);

                Ok(hash)
            }
            None => bail!("No multisig configured"),
        }
    }

    // finalize multisig by signing the transaction
    pub async fn finalize_multisig_transaction(
        &self,
        signatures: Vec<SignatureMultisig>,
    ) -> Result<String> {
        let mut signature_ids = Vec::new();
        for signature in signatures {
            let id = signature.id;
            let signature = Signature::from_hex(&signature.signature)
                .context(format!("Invalid signature for id: {}", id))?;
            signature_ids.push(SignatureId { id, signature });
        }

        let mut multisig = MultiSig::new();
        for signature in signature_ids {
            if !multisig.add_signature(signature) {
                bail!("Invalid signature");
            }
        }

        let (mut unsigned, mut state, transaction_type_builder) = self
            .pending_unsigned
            .write()
            .take()
            .ok_or_else(|| anyhow!("No unsigned transaction available"))?;

        unsigned.set_multisig(multisig);

        let tx = unsigned.finalize(self.wallet.get_keypair());

        state.set_tx_hash_built(tx.hash());

        self.pending_transactions
            .write()
            .insert(tx.hash().clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: tx.hash().to_hex(),
            fee: tx.get_fee(),
            transaction_type: transaction_type_builder,
        })
        .to_string())
    }

    // Sign a multisig transaction
    pub fn multisig_sign(&self, tx_hash: String) -> Result<String> {
        let hash = Hash::from_hex(&tx_hash)?;
        let signature = self.wallet.sign_data(hash.as_bytes());
        Ok(signature.to_hex())
    }

    // Private method to build an unsigned transaction
    async fn build_unsigned_transaction(
        &self,
        tx_type: TransactionTypeBuilder,
        fee: FeeBuilder,
        threshold: u8,
    ) -> Result<(UnsignedTransaction, TransactionBuilderState)> {
        let storage = self.wallet.get_storage().write().await;
        let mut state = self
            .wallet
            .create_transaction_state_with_storage(
                &storage,
                &tx_type,
                fee,
                BaseFeeMode::None,
                None,
                None,
            )
            .await
            .context("Error while creating transaction state")?;

        let unsigned = self
            .wallet
            .create_unsigned_transaction(
                &mut state,
                Some(threshold),
                tx_type,
                fee,
                storage.get_tx_version().await?,
            )
            .context("Error while building unsigned transaction")?;
        info!(
            "Unsigned transaction created: {}",
            unsigned.get_hash_for_multisig()
        );
        Ok((unsigned, state))
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
                encrypt_extra_data: match transfer.encrypt_extra_data {
                    Some(value) => value,
                    None => false,
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
