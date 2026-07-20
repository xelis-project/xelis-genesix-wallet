use std::path::Path;
use std::thread;

use super::super::precomputed_tables::{
    LogProgressTableGenerationReportFunction, PrecomputedTableType,
};
use super::{PrecomputedTablesShared, XelisWallet};
use crate::multisig::PendingMultisigStore;
use anyhow::{anyhow, bail, Result};
use flutter_rust_bridge::frb;
use log::info;
use parking_lot::{Mutex, RwLock};
use serde_json;
use xelis_common::network::Network;
use xelis_wallet::precomputed_tables;
use xelis_wallet::wallet::{RecoverOption, Wallet};

static CACHED_TABLES: Mutex<Option<PrecomputedTablesShared>> = Mutex::new(None);
static MT_PARAMS: Mutex<Option<(usize, usize)>> = Mutex::new(None);

fn mt_params_for_cpu_cores(cpu_cores: usize) -> (usize, usize) {
    let thread_count = (cpu_cores.saturating_sub(2)).max(1).min(32);
    (thread_count, thread_count * 4)
}

fn get_mt_params() -> (usize, usize) {
    let mut guard = MT_PARAMS.lock();

    if let Some(params) = *guard {
        return params;
    }

    let cpu_cores = thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);
    let params = mt_params_for_cpu_cores(cpu_cores);

    *guard = Some(params);
    params
}

fn resolve_wallet_path(name: &str, directory: &str) -> Result<String> {
    if name.is_empty() {
        if directory.is_empty() {
            bail!("Either 'name' or 'directory' must be non-empty");
        }

        return Ok(directory.to_owned());
    }

    Ok(Path::new(directory)
        .join(name)
        .to_string_lossy()
        .into_owned())
}

fn recover_option<'a>(seed: Option<&'a str>, private_key: Option<&'a str>) -> RecoverOption<'a> {
    if let Some(seed) = seed {
        RecoverOption::Seed(seed)
    } else if let Some(private_key) = private_key {
        RecoverOption::PrivateKey(private_key)
    } else {
        RecoverOption::None
    }
}

fn precomputed_table_type_from_l1(size: usize) -> PrecomputedTableType {
    match size {
        precomputed_tables::L1_LOW => PrecomputedTableType::L1Low,
        precomputed_tables::L1_MEDIUM => PrecomputedTableType::L1Medium,
        precomputed_tables::L1_FULL => PrecomputedTableType::L1Full,
        custom => PrecomputedTableType::Custom(custom),
    }
}

pub(super) fn refresh_mt_params() {
    *MT_PARAMS.lock() = None;
    let _ = get_mt_params();
}

pub(super) fn set_mt_params(thread_count: usize, concurrency: usize) {
    *MT_PARAMS.lock() = Some((thread_count, concurrency));
}

pub(super) fn clear_cached_tables() {
    CACHED_TABLES.lock().take();
}

pub(super) fn drop_wallet(wallet: XelisWallet) {
    drop(wallet);
}

pub(super) async fn update_tables(
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

pub(super) fn get_current_precomputed_tables_type() -> Result<PrecomputedTableType> {
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

    Ok(precomputed_table_type_from_l1(size))
}

pub(super) async fn create_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    seed: Option<String>,
    private_key: Option<String>,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> Result<XelisWallet> {
    let full_path = resolve_wallet_path(&name, &directory)?;

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

    let recover = recover_option(seed.as_deref(), private_key.as_deref());

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
        prepared_transaction: RwLock::new(Default::default()),
        pending_multisig: RwLock::new(PendingMultisigStore::default()),
    })
}

pub(super) async fn open_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> Result<XelisWallet> {
    let full_path = resolve_wallet_path(&name, &directory)?;

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
        prepared_transaction: RwLock::new(Default::default()),
        pending_multisig: RwLock::new(PendingMultisigStore::default()),
    })
}

impl XelisWallet {
    pub async fn change_password(&self, old_password: String, new_password: String) -> Result<()> {
        self.wallet.set_password(&old_password, &new_password).await
    }

    pub async fn online_mode(&self, daemon_address: String) -> Result<()> {
        // Genesix owns reconnect attempts from Dart. The upstream auto-reconnect
        // loop can sleep after sync errors and miss stop signals, which blocks
        // logout/close when a daemon is on the wrong network.
        Ok(self.wallet.set_online_mode(&daemon_address, false).await?)
    }

    pub async fn offline_mode(&self) -> Result<()> {
        Ok(self.wallet.set_offline_mode().await?)
    }

    pub async fn is_online(&self) -> bool {
        self.wallet.is_online().await
    }

    pub async fn is_syncing(&self) -> bool {
        let storage = self.wallet.get_storage().read().await;
        storage.is_syncing()
    }

    #[frb(sync)]
    pub fn get_address_str(&self) -> String {
        self.wallet.get_address().to_string()
    }

    #[frb(sync)]
    pub fn get_network(&self) -> Network {
        self.wallet.get_network().clone()
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
        self.wallet.is_valid_password(&password).await
    }

    pub async fn rescan(&self, topoheight: u64) -> Result<()> {
        Ok(self.wallet.rescan(topoheight, true).await?)
    }

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
}

#[cfg(test)]
mod tests;
