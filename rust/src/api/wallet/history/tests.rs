use futures::executor::block_on;
use serde_json::{json, Value};
use xelis_common::crypto::{Hash, KeyPair};
use xelis_common::tokio::sync::broadcast;
use xelis_wallet::wallet::Event;

#[cfg(not(target_arch = "wasm32"))]
use std::{fs, io::Write};
#[cfg(not(target_arch = "wasm32"))]
use tempfile::tempdir;

#[cfg(not(target_arch = "wasm32"))]
use super::{create_temporary_csv_file, persist_csv_file};
use super::{
    ensure_transactions_to_export, forward_wallet_events, page_is_out_of_range,
    serialize_wallet_event,
};
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

#[test]
fn csv_export_requires_at_least_one_transaction() {
    assert_eq!(
        ensure_transactions_to_export(0).unwrap_err().to_string(),
        "No transactions to export"
    );
    assert!(ensure_transactions_to_export(1).is_ok());
}

#[cfg(not(target_arch = "wasm32"))]
#[test]
fn csv_destination_is_replaced_only_after_the_temporary_file_is_complete() {
    let directory = tempdir().unwrap();
    let destination = directory.path().join("history.csv");
    fs::write(&destination, "existing export").unwrap();

    let mut temporary = create_temporary_csv_file(&destination).unwrap();
    temporary.write_all(b"replacement export").unwrap();

    assert_eq!(fs::read_to_string(&destination).unwrap(), "existing export");

    persist_csv_file(temporary, &destination).unwrap();
    assert_eq!(
        fs::read_to_string(&destination).unwrap(),
        "replacement export"
    );
}

#[test]
fn wallet_event_envelope_preserves_kind_and_data() {
    let serialized = serialize_wallet_event(&Event::NewTopoHeight { topoheight: 42 }).unwrap();
    let value: Value = serde_json::from_str(&serialized).unwrap();

    assert_eq!(
        value,
        json!({
            "event": "new_topo_height",
            "data": { "topoheight": 42 }
        })
    );
}

#[test]
fn wallet_events_are_forwarded_in_order_until_the_channel_closes() {
    let (sender, receiver) = broadcast::channel(4);
    sender.send(Event::NewTopoHeight { topoheight: 7 }).unwrap();
    sender.send(Event::HistorySynced { topoheight: 9 }).unwrap();
    drop(sender);

    let mut forwarded = Vec::new();
    block_on(forward_wallet_events(receiver, |event| {
        forwarded.push(event);
        Ok::<(), ()>(())
    }));

    let values = forwarded
        .iter()
        .map(|event| serde_json::from_str::<Value>(event).unwrap())
        .collect::<Vec<_>>();
    assert_eq!(values.len(), 2);
    assert_eq!(values[0]["event"], "new_topo_height");
    assert_eq!(values[0]["data"]["topoheight"], 7);
    assert_eq!(values[1]["event"], "history_synced");
    assert_eq!(values[1]["data"]["topoheight"], 9);
}

#[test]
fn wallet_event_forwarding_stops_when_the_sink_rejects_an_event() {
    let (sender, receiver) = broadcast::channel(4);
    sender.send(Event::Online).unwrap();
    sender.send(Event::Offline).unwrap();

    let mut attempts = 0;
    block_on(forward_wallet_events(receiver, |_| {
        attempts += 1;
        Err::<(), ()>(())
    }));

    assert_eq!(attempts, 1);
    assert!(sender.send(Event::Online).is_err());
}

#[test]
fn wallet_event_forwarding_recovers_after_receiver_lag() {
    let (sender, receiver) = broadcast::channel(1);
    sender.send(Event::NewTopoHeight { topoheight: 1 }).unwrap();
    sender.send(Event::NewTopoHeight { topoheight: 2 }).unwrap();
    sender.send(Event::NewTopoHeight { topoheight: 3 }).unwrap();
    drop(sender);

    let mut forwarded = Vec::new();
    block_on(forward_wallet_events(receiver, |event| {
        forwarded.push(event);
        Ok::<(), ()>(())
    }));

    assert_eq!(forwarded.len(), 1);
    let value: Value = serde_json::from_str(&forwarded[0]).unwrap();
    assert_eq!(value["data"]["topoheight"], 3);
}
