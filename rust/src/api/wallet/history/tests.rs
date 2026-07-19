use xelis_common::crypto::{Hash, KeyPair};

use super::page_is_out_of_range;
use crate::api::models::wallet_dtos::HistoryPageFilter;

fn filter() -> HistoryPageFilter {
    HistoryPageFilter {
        page: 1,
        limit: Some(10),
        asset_hash: None,
        address: None,
        min_topoheight: None,
        max_topoheight: None,
        accept_incoming: true,
        accept_outgoing: true,
        accept_coinbase: true,
        accept_burn: true,
        accept_blob: true,
        min_timestamp: None,
        max_timestamp: None,
    }
}

#[test]
fn history_pagination_is_one_based() {
    let first_page = filter();
    let options = first_page.options().unwrap();

    assert_eq!(options.skip, Some(0));
    assert_eq!(options.limit, Some(10));

    let mut second_page = filter();
    second_page.page = 2;
    second_page.limit = Some(25);
    assert_eq!(second_page.options().unwrap().skip, Some(25));
}

#[test]
fn history_rejects_zero_page_and_limit() {
    let mut zero_page = filter();
    zero_page.page = 0;
    assert_eq!(
        zero_page.options().unwrap_err().to_string(),
        "Page must be at least 1"
    );

    let mut zero_limit = filter();
    zero_limit.limit = Some(0);
    assert_eq!(
        zero_limit.options().unwrap_err().to_string(),
        "Limit cannot be 0"
    );
}

#[test]
fn history_rejects_a_pagination_offset_overflow() {
    let mut overflowing = filter();
    overflowing.page = usize::MAX;
    overflowing.limit = Some(2);

    assert_eq!(
        overflowing.options().unwrap_err().to_string(),
        "Pagination offset is too large"
    );
}

#[test]
fn history_detects_pages_beyond_the_available_transactions() {
    assert!(!page_is_out_of_range(5, 1, 2));
    assert!(!page_is_out_of_range(5, 3, 2));
    assert!(page_is_out_of_range(5, 4, 2));
}

#[test]
fn address_filter_disables_global_transaction_kinds() {
    let address = KeyPair::new().get_public_key().to_address(false);
    let mut filtered = filter();
    filtered.address = Some(address.to_string());

    let options = filtered.options().unwrap();

    assert!(options.address.is_some());
    assert!(!options.accept_coinbase);
    assert!(!options.accept_burn);
    assert!(!options.accept_blob);
}

#[test]
fn asset_filter_disables_blob_but_preserves_other_requested_kinds() {
    let mut filtered = filter();
    filtered.asset_hash = Some(Hash::new([4; 32]).to_hex());

    let options = filtered.options().unwrap();

    assert!(options.asset.is_some());
    assert!(options.accept_coinbase);
    assert!(options.accept_burn);
    assert!(!options.accept_blob);
}

#[test]
fn history_rejects_invalid_address_and_asset_filters() {
    let mut invalid_address = filter();
    invalid_address.address = Some("invalid-address".to_owned());
    assert!(invalid_address
        .options()
        .unwrap_err()
        .to_string()
        .starts_with("Invalid address"));

    let mut invalid_asset = filter();
    invalid_asset.asset_hash = Some("invalid-asset".to_owned());
    assert!(invalid_asset
        .options()
        .unwrap_err()
        .to_string()
        .starts_with("Invalid asset"));
}
