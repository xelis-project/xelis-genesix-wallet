use std::path::Path;

use xelis_wallet::precomputed_tables::{L1_FULL, L1_LOW, L1_MEDIUM};
use xelis_wallet::wallet::RecoverOption;

use super::{
    mt_params_for_cpu_cores, precomputed_table_type_from_l1, recover_option, resolve_wallet_path,
};
use crate::api::precomputed_tables::PrecomputedTableType;

#[test]
fn wallet_path_uses_directory_when_name_is_empty() {
    assert_eq!(
        resolve_wallet_path("", "wallet-directory").unwrap(),
        "wallet-directory"
    );
}

#[test]
fn wallet_path_joins_directory_and_name() {
    let path = resolve_wallet_path("primary", "wallets").unwrap();

    assert_eq!(path, Path::new("wallets").join("primary").to_string_lossy());
}

#[test]
fn wallet_path_accepts_name_without_directory() {
    assert_eq!(resolve_wallet_path("primary", "").unwrap(), "primary");
}

#[test]
fn wallet_path_rejects_empty_name_and_directory() {
    let error = resolve_wallet_path("", "").unwrap_err();

    assert_eq!(
        error.to_string(),
        "Either 'name' or 'directory' must be non-empty"
    );
}

#[test]
fn mt_params_reserve_cores_and_apply_bounds() {
    assert_eq!(mt_params_for_cpu_cores(0), (1, 4));
    assert_eq!(mt_params_for_cpu_cores(1), (1, 4));
    assert_eq!(mt_params_for_cpu_cores(2), (1, 4));
    assert_eq!(mt_params_for_cpu_cores(8), (6, 24));
    assert_eq!(mt_params_for_cpu_cores(64), (32, 128));
}

#[test]
fn recovery_prefers_seed_then_private_key() {
    assert!(matches!(
        recover_option(Some("seed words"), Some("private-key")),
        RecoverOption::Seed("seed words")
    ));
    assert!(matches!(
        recover_option(None, Some("private-key")),
        RecoverOption::PrivateKey("private-key")
    ));
    assert!(matches!(recover_option(None, None), RecoverOption::None));
}

#[test]
fn l1_sizes_map_to_known_and_custom_table_types() {
    assert!(matches!(
        precomputed_table_type_from_l1(L1_LOW),
        PrecomputedTableType::L1Low
    ));
    assert!(matches!(
        precomputed_table_type_from_l1(L1_MEDIUM),
        PrecomputedTableType::L1Medium
    ));
    assert!(matches!(
        precomputed_table_type_from_l1(L1_FULL),
        PrecomputedTableType::L1Full
    ));
    assert!(matches!(
        precomputed_table_type_from_l1(24),
        PrecomputedTableType::Custom(24)
    ));
}
