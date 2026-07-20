use std::sync::{Arc, RwLock as SharedTableRwLock};

use xelis_wallet::precomputed_tables::{L1_FULL, L1_LOW, L1_MEDIUM};

use super::{PrecomputedTablesCache, PRECOMPUTED_TABLES_LOAD_LOCK};

#[test]
fn reuses_a_compatible_shared_instance() {
    let mut cache = PrecomputedTablesCache::new();

    assert!(cache.get_or_require_load(L1_LOW).unwrap().is_none());

    let low_tables = Arc::new(SharedTableRwLock::new("low tables"));
    let installed = cache.install(L1_LOW, low_tables).unwrap();

    assert!(Arc::ptr_eq(
        &installed,
        &cache.get_or_require_load(L1_LOW).unwrap().unwrap()
    ));
    assert!(cache.get_or_require_load(L1_MEDIUM).unwrap().is_none());
    assert_eq!(cache.current_l1(), Some(L1_LOW));

    assert!(!cache.clear_if_unused());
    assert_eq!(cache.current_l1(), Some(L1_LOW));

    drop(installed);

    assert!(cache.clear_if_unused());
    assert_eq!(cache.current_l1(), None);
}

#[test]
fn upgrades_every_existing_wallet_without_downgrading() {
    let mut cache = PrecomputedTablesCache::new();
    let low_tables = Arc::new(SharedTableRwLock::new("low tables"));
    let wallet_tables = cache.install(L1_LOW, low_tables).unwrap();

    let upgraded_tables = cache
        .install(L1_FULL, Arc::new(SharedTableRwLock::new("full tables")))
        .unwrap();

    assert!(Arc::ptr_eq(&wallet_tables, &upgraded_tables));
    assert!(Arc::ptr_eq(
        &wallet_tables,
        &cache.get_or_require_load(L1_FULL).unwrap().unwrap()
    ));
    assert_eq!(*wallet_tables.read().unwrap(), "full tables");
    assert_eq!(cache.current_l1(), Some(L1_FULL));

    let after_smaller_install = cache
        .install(L1_MEDIUM, Arc::new(SharedTableRwLock::new("medium tables")))
        .unwrap();

    assert!(Arc::ptr_eq(&wallet_tables, &after_smaller_install));
    assert!(Arc::ptr_eq(
        &wallet_tables,
        &cache.get_or_require_load(L1_LOW).unwrap().unwrap()
    ));
    assert_eq!(*wallet_tables.read().unwrap(), "full tables");
    assert_eq!(cache.current_l1(), Some(L1_FULL));
}

#[test]
fn allows_only_one_upgrade_after_low() {
    let mut cache = PrecomputedTablesCache::new();
    cache
        .install(L1_MEDIUM, Arc::new(SharedTableRwLock::new("medium tables")))
        .unwrap();

    let error = cache
        .get_or_require_load(L1_FULL)
        .err()
        .expect("a finalized table must reject another upgrade");

    assert_eq!(
        error.to_string(),
        format!(
            "Precomputed tables are already finalized at L1 {L1_MEDIUM}; refusing a second upgrade to L1 {L1_FULL}"
        )
    );
    assert!(cache
        .install(L1_FULL, Arc::new(SharedTableRwLock::new("full tables")))
        .is_err());
    assert_eq!(cache.current_l1(), Some(L1_MEDIUM));
}

#[test]
fn loads_are_application_wide_and_exclusive() {
    let first_load = PRECOMPUTED_TABLES_LOAD_LOCK
        .try_lock()
        .expect("the load lock must initially be available");

    assert!(PRECOMPUTED_TABLES_LOAD_LOCK.try_lock().is_none());

    drop(first_load);

    assert!(PRECOMPUTED_TABLES_LOAD_LOCK.try_lock().is_some());
}
