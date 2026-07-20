use std::sync::{Arc, RwLock as SharedTableRwLock};

use anyhow::{anyhow, bail, Result};
use futures::lock::Mutex as AsyncMutex;
use log::{info, warn};
use parking_lot::Mutex as StateMutex;
use xelis_common::crypto::ecdlp;
use xelis_wallet::precomputed_tables;

use super::super::PrecomputedTablesShared;
use crate::api::precomputed_tables::LogProgressTableGenerationReportFunction;

struct CachedPrecomputedTables<T> {
    l1_size: usize,
    // Every wallet clones this Arc. Upgrades replace its inner value so all
    // current and future wallets observe the new tables without reopening.
    tables: Arc<SharedTableRwLock<T>>,
}

struct PrecomputedTablesCache<T> {
    entry: Option<CachedPrecomputedTables<T>>,
}

impl<T> PrecomputedTablesCache<T> {
    const fn new() -> Self {
        Self { entry: None }
    }

    fn current_l1(&self) -> Option<usize> {
        self.entry.as_ref().map(|entry| entry.l1_size)
    }

    fn clear_if_unused(&mut self) -> bool {
        if self
            .entry
            .as_ref()
            .is_some_and(|entry| Arc::strong_count(&entry.tables) > 1)
        {
            return false;
        }

        self.entry = None;
        true
    }

    fn get_or_require_load(
        &self,
        requested_l1: usize,
    ) -> Result<Option<Arc<SharedTableRwLock<T>>>> {
        let Some(entry) = self.entry.as_ref() else {
            return Ok(None);
        };

        if entry.l1_size >= requested_l1 {
            return Ok(Some(entry.tables.clone()));
        }

        if entry.l1_size == precomputed_tables::L1_LOW {
            return Ok(None);
        }

        bail!(
            "Precomputed tables are already finalized at L1 {}; refusing a second upgrade to L1 {}",
            entry.l1_size,
            requested_l1
        )
    }

    fn install(
        &mut self,
        l1_size: usize,
        loaded_tables: Arc<SharedTableRwLock<T>>,
    ) -> Result<Arc<SharedTableRwLock<T>>> {
        let Some(entry) = self.entry.as_mut() else {
            self.entry = Some(CachedPrecomputedTables {
                l1_size,
                tables: loaded_tables.clone(),
            });
            return Ok(loaded_tables);
        };

        // A larger table can serve a smaller request.
        if entry.l1_size >= l1_size {
            return Ok(entry.tables.clone());
        }

        if entry.l1_size != precomputed_tables::L1_LOW {
            bail!(
                "Precomputed tables are already finalized at L1 {}; refusing a second upgrade to L1 {}",
                entry.l1_size,
                l1_size
            );
        }

        let replacement = Arc::try_unwrap(loaded_tables)
            .map_err(|_| anyhow!("Loaded precomputed tables are unexpectedly shared"))?
            .into_inner()
            .map_err(|_| anyhow!("Loaded precomputed tables lock is poisoned"))?;

        let previous = {
            let mut current = entry
                .tables
                .write()
                .map_err(|_| anyhow!("Application precomputed tables lock is poisoned"))?;
            std::mem::replace(&mut *current, replacement)
        };

        entry.l1_size = l1_size;
        let shared_tables = entry.tables.clone();

        // Dropping a large table may be costly, so keep it outside the write lock.
        drop(previous);

        Ok(shared_tables)
    }
}

static CACHED_TABLES: StateMutex<PrecomputedTablesCache<ecdlp::ECDLPTables>> =
    StateMutex::new(PrecomputedTablesCache::new());
static PRECOMPUTED_TABLES_LOAD_LOCK: AsyncMutex<()> = AsyncMutex::new(());

pub(super) async fn get_or_load_precomputed_tables(
    precomputed_tables_path: Option<&str>,
    requested_l1: usize,
) -> Result<PrecomputedTablesShared> {
    if let Some(tables) = CACHED_TABLES.lock().get_or_require_load(requested_l1)? {
        info!("Using cached precomputed tables for L1 size {requested_l1}.");
        return Ok(tables);
    }

    // Loading and generation are application-wide operations. Waiting here
    // prevents two callers from reading or generating tables in parallel.
    let _load_guard = PRECOMPUTED_TABLES_LOAD_LOCK.lock().await;

    // A previous waiter may have installed the requested or final tables.
    if let Some(tables) = CACHED_TABLES.lock().get_or_require_load(requested_l1)? {
        return Ok(tables);
    }

    info!("Loading precomputed tables for L1 size {requested_l1}...");
    let loaded_tables = precomputed_tables::read_or_generate_precomputed_tables(
        precomputed_tables_path,
        requested_l1,
        LogProgressTableGenerationReportFunction,
        true,
    )
    .await?;

    CACHED_TABLES.lock().install(requested_l1, loaded_tables)
}

pub(super) fn clear_cached_tables() {
    if !CACHED_TABLES.lock().clear_if_unused() {
        warn!("Keeping precomputed tables cached because they are still used by a wallet.");
    }
}

pub(super) fn current_l1() -> Option<usize> {
    CACHED_TABLES.lock().current_l1()
}

#[cfg(test)]
mod tests;
