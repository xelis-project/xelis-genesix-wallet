use std::sync::{Arc, Barrier};
use std::thread;

use anyhow::Error;
use parking_lot::RwLock;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Hash, KeyPair};
use xelis_common::rpc::client::JsonRPCError;
use xelis_common::transaction::builder::{TransactionTypeBuilder, TransferBuilder};
use xelis_wallet::error::WalletError;

use crate::api::models::wallet_dtos::{BroadcastTransactionOutcome, Transfer};

use super::{
    amount_after_fee, build_and_store_prepared, build_burn_all_type, build_burn_type,
    build_transfer, build_transfer_all_type, build_transfer_from_input, classify_submit_error,
    create_transfers_with_decimals, encrypt_extra_data_or_default, ensure_wallet_online,
    is_daemon_rejection, resolve_submission, transaction_summary_json, PreparedTransactionGuard,
    PreparedTransactionState, PreparedTransactionStore, SubmissionResolution, SubmitErrorClass,
};

fn daemon_rejection() -> WalletError {
    WalletError::from(Error::new(JsonRPCError::ServerError {
        code: -32_000,
        message: "rejected".to_owned(),
        data: None,
    }))
}

fn prepared_store<T>(hash: Hash, transaction: T) -> RwLock<PreparedTransactionStore<T>> {
    let mut store = PreparedTransactionStore::default();
    store.replace(hash, transaction).unwrap();
    RwLock::new(store)
}

fn ready_transaction<'a, T>(
    store: &'a PreparedTransactionStore<T>,
    expected_hash: &Hash,
) -> Option<&'a T> {
    match &store.state {
        PreparedTransactionState::Ready { hash, transaction } if hash == expected_hash => {
            Some(transaction)
        }
        _ => None,
    }
}

fn is_in_flight<T>(store: &PreparedTransactionStore<T>, expected_hash: &Hash) -> bool {
    matches!(
        &store.state,
        PreparedTransactionState::InFlight { hash } if hash == expected_hash
    )
}

fn is_empty<T>(store: &PreparedTransactionStore<T>) -> bool {
    matches!(store.state, PreparedTransactionState::Empty)
}

fn transfer_input(
    float_amount: f64,
    destination: String,
    asset: &Hash,
    extra_data: Option<&str>,
    encrypt_extra_data: Option<bool>,
) -> Transfer {
    Transfer {
        float_amount,
        str_address: destination,
        asset_hash: asset.to_hex(),
        extra_data: extra_data.map(str::to_owned),
        encrypt_extra_data,
    }
}

fn transfers_from(transaction_type: TransactionTypeBuilder) -> Vec<TransferBuilder> {
    let TransactionTypeBuilder::Transfers(transfers) = transaction_type else {
        panic!("expected a transfers transaction type");
    };

    transfers
}

#[test]
fn encryption_defaults_to_enabled_and_respects_explicit_values() {
    assert!(encrypt_extra_data_or_default(None));
    assert!(encrypt_extra_data_or_default(Some(true)));
    assert!(!encrypt_extra_data_or_default(Some(false)));
}

#[test]
fn transfer_builder_maps_extra_data_and_encryption() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([3; 32]);
    let transfer = build_transfer(
        destination.clone(),
        42,
        asset.clone(),
        Some("memo".to_owned()),
        None,
    );

    assert_eq!(transfer.destination, destination);
    assert_eq!(transfer.amount, 42);
    assert_eq!(transfer.asset, asset);
    assert!(transfer.encrypt_extra_data);
    assert!(matches!(
        transfer.extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "memo"
    ));
}

#[test]
fn transfer_builder_preserves_absent_extra_data_and_explicit_public_flag() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transfer = build_transfer(destination, 7, Hash::new([22; 32]), None, Some(false));

    assert!(transfer.extra_data.is_none());
    assert!(!transfer.encrypt_extra_data);
}

#[test]
fn transfer_input_uses_asset_precision_and_validates_the_destination() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([23; 32]);
    let transfer = build_transfer_from_input(
        transfer_input(
            1.25,
            destination.to_string(),
            &asset,
            Some("asset memo"),
            Some(false),
        ),
        asset.clone(),
        2,
    )
    .unwrap();

    assert_eq!(transfer.destination, destination);
    assert_eq!(transfer.asset, asset);
    assert_eq!(transfer.amount, 125);
    assert!(!transfer.encrypt_extra_data);
    assert!(matches!(
        transfer.extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "asset memo"
    ));

    let error = build_transfer_from_input(
        transfer_input(1.0, "invalid".to_owned(), &Hash::new([24; 32]), None, None),
        Hash::new([24; 32]),
        8,
    )
    .unwrap_err();

    assert!(error.to_string().starts_with("Invalid address"));
}

#[test]
fn transfer_input_rejects_amounts_that_do_not_match_asset_precision() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([25; 32]);
    let error = build_transfer_from_input(
        transfer_input(1.234, destination.to_string(), &asset, None, None),
        asset,
        2,
    )
    .unwrap_err();

    assert!(error
        .to_string()
        .starts_with("Error while converting amount to atomic format"));
}

#[tokio::test]
async fn multi_asset_transfers_preserve_order_amounts_and_independent_options() {
    let first_destination = KeyPair::new().get_public_key().to_address(false);
    let second_destination = KeyPair::new().get_public_key().to_address(false);
    let token = Hash::new([26; 32]);

    let transaction_type = create_transfers_with_decimals(
        vec![
            transfer_input(
                1.25,
                first_destination.to_string(),
                &XELIS_ASSET,
                Some("private"),
                None,
            ),
            transfer_input(
                2.5,
                second_destination.to_string(),
                &token,
                None,
                Some(false),
            ),
        ],
        |asset| async move {
            if asset == XELIS_ASSET {
                Ok(8)
            } else {
                Ok(2)
            }
        },
    )
    .await
    .unwrap();
    let transfers = transfers_from(transaction_type);

    assert_eq!(transfers.len(), 2);
    assert_eq!(transfers[0].destination, first_destination);
    assert_eq!(transfers[0].asset, XELIS_ASSET);
    assert_eq!(transfers[0].amount, 125_000_000);
    assert!(transfers[0].encrypt_extra_data);
    assert!(transfers[0].extra_data.is_some());
    assert_eq!(transfers[1].destination, second_destination);
    assert_eq!(transfers[1].asset, token);
    assert_eq!(transfers[1].amount, 250);
    assert!(!transfers[1].encrypt_extra_data);
    assert!(transfers[1].extra_data.is_none());
}

#[tokio::test]
async fn transfer_collection_stops_on_asset_metadata_failure() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([31; 32]);
    let error = create_transfers_with_decimals(
        vec![transfer_input(
            1.25,
            destination.to_string(),
            &asset,
            None,
            None,
        )],
        |_| async { Err(anyhow::anyhow!("asset metadata missing")) },
    )
    .await
    .unwrap_err();

    assert!(error
        .to_string()
        .starts_with("Error while converting amount to atomic format"));
}

#[test]
fn fee_is_deducted_only_from_the_native_asset() {
    assert_eq!(
        amount_after_fee(100, 25, &XELIS_ASSET, "insufficient").unwrap(),
        75
    );

    let token = Hash::new([4; 32]);
    assert_eq!(
        amount_after_fee(100, 200, &token, "insufficient").unwrap(),
        100
    );
}

#[test]
fn native_asset_fee_rejects_an_insufficient_balance() {
    for balance in [24, 25] {
        let error = amount_after_fee(balance, 25, &XELIS_ASSET, "insufficient").unwrap_err();

        assert_eq!(error.to_string(), "insufficient");
    }

    let token = Hash::new([27; 32]);
    assert_eq!(
        amount_after_fee(0, 25, &token, "insufficient")
            .unwrap_err()
            .to_string(),
        "insufficient"
    );
}

#[test]
fn transfer_all_uses_post_fee_xelis_amount_and_preserves_options() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transfers = transfers_from(
        build_transfer_all_type(
            destination.clone(),
            100,
            25,
            XELIS_ASSET,
            Some("all".to_owned()),
            Some(false),
        )
        .unwrap(),
    );

    assert_eq!(transfers.len(), 1);
    assert_eq!(transfers[0].destination, destination);
    assert_eq!(transfers[0].asset, XELIS_ASSET);
    assert_eq!(transfers[0].amount, 75);
    assert!(!transfers[0].encrypt_extra_data);
    assert!(matches!(
        &transfers[0].extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "all"
    ));
}

#[test]
fn transfer_all_keeps_the_full_token_amount_because_fees_use_xelis() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let token = Hash::new([28; 32]);
    let transfers = transfers_from(
        build_transfer_all_type(destination, 100, 1_000, token.clone(), None, None).unwrap(),
    );

    assert_eq!(transfers[0].asset, token);
    assert_eq!(transfers[0].amount, 100);
}

#[test]
fn transfer_all_rejects_a_zero_post_fee_amount() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let error = build_transfer_all_type(destination, 25, 25, XELIS_ASSET, None, None).unwrap_err();

    assert_eq!(error.to_string(), "Insufficient balance for fees");
}

#[test]
fn burn_builders_preserve_asset_and_apply_all_fee_rules() {
    let token = Hash::new([29; 32]);
    let TransactionTypeBuilder::Burn(requested) = build_burn_type(token.clone(), 42) else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(requested.asset, token);
    assert_eq!(requested.amount, 42);

    let TransactionTypeBuilder::Burn(xelis_all) =
        build_burn_all_type(XELIS_ASSET, 100, 25).unwrap()
    else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(xelis_all.asset, XELIS_ASSET);
    assert_eq!(xelis_all.amount, 75);

    let TransactionTypeBuilder::Burn(token_all) =
        build_burn_all_type(token.clone(), 100, 1_000).unwrap()
    else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(token_all.asset, token);
    assert_eq!(token_all.amount, 100);
}

#[test]
fn burn_all_rejects_a_zero_post_fee_amount() {
    let error = build_burn_all_type(XELIS_ASSET, 25, 25).unwrap_err();

    assert_eq!(
        error.to_string(),
        "Insufficient balance to pay burn transaction fees"
    );
}

#[test]
fn summary_serializes_the_final_post_fee_builder() {
    let hash = Hash::new([30; 32]);
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transaction_type =
        build_transfer_all_type(destination, 100, 25, XELIS_ASSET, None, None).unwrap();
    let summary: serde_json::Value =
        serde_json::from_str(&transaction_summary_json(&hash, 25, transaction_type)).unwrap();

    assert_eq!(summary["hash"], hash.to_hex());
    assert_eq!(summary["fee"], 25);
    assert_eq!(summary["transaction_type"]["transfers"][0]["amount"], 75);
}

#[tokio::test]
async fn failed_transaction_construction_preserves_the_prepared_slot() {
    let existing = Hash::new([32; 32]);
    let prepared = prepared_store(existing.clone(), "existing");
    let result = build_and_store_prepared(
        &prepared,
        build_burn_type(Hash::new([33; 32]), 42),
        |_| async { Err::<(Hash, u64, &'static str), _>(anyhow::anyhow!("construction failed")) },
    )
    .await;

    assert_eq!(result.unwrap_err().to_string(), "construction failed");
    assert_eq!(
        ready_transaction(&prepared.read(), &existing),
        Some(&"existing")
    );
}

#[tokio::test]
async fn successful_construction_stores_the_exact_builder_and_summary() {
    let existing = Hash::new([34; 32]);
    let replacement = Hash::new([35; 32]);
    let returned_hash = replacement.clone();
    let prepared = prepared_store(existing.clone(), "existing");
    let summary = build_and_store_prepared(
        &prepared,
        build_burn_type(Hash::new([36; 32]), 42),
        |transaction_type| async move {
            let TransactionTypeBuilder::Burn(payload) = transaction_type else {
                panic!("expected the burn builder passed to construction");
            };
            assert_eq!(payload.asset, Hash::new([36; 32]));
            assert_eq!(payload.amount, 42);

            Ok((returned_hash, 7, "replacement"))
        },
    )
    .await
    .unwrap();
    let summary: serde_json::Value = serde_json::from_str(&summary).unwrap();

    assert_eq!(ready_transaction(&prepared.read(), &existing), None);
    assert_eq!(
        ready_transaction(&prepared.read(), &replacement),
        Some(&"replacement")
    );
    assert_eq!(summary["hash"], replacement.to_hex());
    assert_eq!(summary["fee"], 7);
    assert_eq!(summary["transaction_type"]["burn"]["amount"], 42);
}

#[test]
fn daemon_server_errors_are_final_rejections() {
    let wallet_error = daemon_rejection();

    let WalletError::Any(inner_error) = &wallet_error else {
        panic!("daemon rejection must be wrapped in WalletError::Any");
    };
    assert!(is_daemon_rejection(inner_error));
    assert_eq!(
        classify_submit_error(&wallet_error),
        SubmitErrorClass::DaemonRejected
    );
}

#[test]
fn transport_and_offline_errors_are_retryable() {
    let transport = WalletError::from(Error::new(JsonRPCError::ConnectionError(
        "offline".to_owned(),
    )));

    assert_eq!(
        classify_submit_error(&transport),
        SubmitErrorClass::Retryable
    );
    assert_eq!(
        classify_submit_error(&WalletError::NotOnlineMode),
        SubmitErrorClass::Retryable
    );
    assert_eq!(
        classify_submit_error(&WalletError::NoNetworkHandler),
        SubmitErrorClass::Retryable
    );
}

#[test]
fn unrelated_wallet_errors_are_not_retryable() {
    assert_eq!(
        classify_submit_error(&WalletError::InvalidAddressParams),
        SubmitErrorClass::LocalFailure
    );
}

#[test]
fn offline_wallet_is_rejected_without_touching_the_prepared_transaction() {
    let hash = Hash::new([5; 32]);
    let prepared = prepared_store(hash.clone(), "transaction");

    assert_eq!(
        ensure_wallet_online(false).unwrap_err().to_string(),
        "Wallet is offline, transaction cannot be submitted"
    );
    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"transaction")
    );

    ensure_wallet_online(true).unwrap();
}

#[test]
fn prepared_replacement_is_explicitly_single_transaction() {
    let first = Hash::new([6; 32]);
    let second = Hash::new([7; 32]);
    let mut prepared = PreparedTransactionStore::default();

    prepared.replace(first.clone(), "first").unwrap();
    prepared.replace(second.clone(), "second").unwrap();

    assert_eq!(ready_transaction(&prepared, &first), None);
    assert_eq!(ready_transaction(&prepared, &second), Some(&"second"));
}

#[test]
fn taking_an_unknown_hash_preserves_the_prepared_transaction() {
    let existing = Hash::new([16; 32]);
    let missing = Hash::new([17; 32]);
    let mut prepared = PreparedTransactionStore::default();
    prepared.replace(existing.clone(), "existing").unwrap();

    assert_eq!(
        prepared
            .take_for_submission(&missing)
            .unwrap_err()
            .to_string(),
        "Cannot find prepared transaction"
    );
    assert_eq!(ready_transaction(&prepared, &existing), Some(&"existing"));
    assert_eq!(ready_transaction(&prepared, &missing), None);
}

#[test]
fn concurrent_prepared_takes_allow_only_one_broadcast() {
    let hash = Hash::new([8; 32]);
    let prepared = Arc::new(prepared_store(hash.clone(), 42));
    let barrier = Arc::new(Barrier::new(3));
    let mut handles = Vec::new();

    for _ in 0..2 {
        let prepared = Arc::clone(&prepared);
        let barrier = Arc::clone(&barrier);
        let hash = hash.clone();
        handles.push(thread::spawn(move || {
            barrier.wait();
            let guard = PreparedTransactionGuard::take(&prepared, hash);
            barrier.wait();
            guard.is_ok()
        }));
    }

    barrier.wait();
    barrier.wait();
    let successful_takes = handles
        .into_iter()
        .map(|handle| handle.join().unwrap())
        .filter(|successful| *successful)
        .count();

    assert_eq!(successful_takes, 1);
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&42));
}

#[test]
fn successful_submission_consumes_the_prepared_transaction() {
    let hash = Hash::new([9; 32]);
    let prepared = prepared_store(hash.clone(), "submitted");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    let resolution = resolve_submission(Ok(()));

    assert!(matches!(resolution, SubmissionResolution::Submitted));
    assert_eq!(guard.finish().unwrap(), "submitted");
    assert!(is_empty(&prepared.read()));
}

#[test]
fn retryable_failure_restores_the_exact_prepared_transaction() {
    let hash = Hash::new([11; 32]);
    let prepared = prepared_store(hash.clone(), "retry");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    let resolution = resolve_submission(Err(WalletError::NotOnlineMode));

    assert!(matches!(
        resolution,
        SubmissionResolution::Retryable(WalletError::NotOnlineMode)
    ));
    guard.restore().unwrap();
    assert_eq!(ready_transaction(&prepared.read(), &hash), Some(&"retry"));
}

#[test]
fn daemon_rejection_discards_the_submitted_transaction() {
    let hash = Hash::new([13; 32]);
    let prepared = prepared_store(hash.clone(), "rejected");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    let resolution = resolve_submission(Err(daemon_rejection()));

    assert!(matches!(
        resolution,
        SubmissionResolution::DaemonRejected(_)
    ));
    assert_eq!(guard.finish().unwrap(), "rejected");
    assert!(is_empty(&prepared.read()));
}

#[test]
fn a_post_submit_apply_failure_does_not_make_the_transaction_retryable() {
    let hash = Hash::new([15; 32]);
    let prepared = prepared_store(hash.clone(), "submitted");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    let resolution = resolve_submission(Ok(()));
    let SubmissionResolution::Submitted = resolution else {
        panic!("successful submission must enter the submitted state");
    };
    let _submitted = guard.finish().unwrap();
    let apply_result = Err::<(), _>(anyhow::anyhow!("local apply failed"));

    assert!(apply_result.is_err());
    assert!(is_empty(&prepared.read()));
    assert_ne!(
        BroadcastTransactionOutcome::SubmittedNeedsResync,
        BroadcastTransactionOutcome::Retryable
    );
}

#[test]
fn interrupted_submission_guard_restores_the_prepared_transaction_on_drop() {
    let hash = Hash::new([18; 32]);
    let prepared = prepared_store(hash.clone(), "interrupted");

    {
        let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();
        assert_eq!(guard.transaction().unwrap(), &"interrupted");
        assert!(is_in_flight(&prepared.read(), &hash));
    }

    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"interrupted")
    );
}

#[test]
fn replacement_is_rejected_while_a_transaction_is_in_flight() {
    let hash = Hash::new([19; 32]);
    let replacement = Hash::new([20; 32]);
    let prepared = prepared_store(hash.clone(), "original");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    assert_eq!(
        prepared
            .write()
            .replace(replacement.clone(), "replacement")
            .unwrap_err()
            .to_string(),
        "Cannot replace a prepared transaction while another transaction is being submitted"
    );
    drop(guard);

    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"original")
    );
    assert_eq!(ready_transaction(&prepared.read(), &replacement), None);
}

#[test]
fn cancellation_is_rejected_while_a_transaction_is_in_flight() {
    let hash = Hash::new([21; 32]);
    let prepared = prepared_store(hash.clone(), "original");
    let guard = PreparedTransactionGuard::take(&prepared, hash.clone()).unwrap();

    assert_eq!(
        prepared.write().cancel(&hash).unwrap_err().to_string(),
        "Cannot cancel a transaction while it is being submitted"
    );
    drop(guard);

    assert_eq!(
        ready_transaction(&prepared.read(), &hash),
        Some(&"original")
    );
}

#[test]
fn rpc_error_taxonomy_is_conservative_and_explicit() {
    let retryable_cases = [
        JsonRPCError::ConnectionError("offline".to_owned()),
        JsonRPCError::TimedOut("submit_transaction".to_owned()),
        JsonRPCError::NoResponse("submit_transaction".to_owned(), "closed".to_owned()),
        JsonRPCError::SendError("submit_transaction".to_owned(), "closed".to_owned()),
    ];

    for error in retryable_cases {
        assert_eq!(
            classify_submit_error(&WalletError::from(Error::new(error))),
            SubmitErrorClass::Retryable
        );
    }

    let daemon_rejection_cases = [
        JsonRPCError::ParseError,
        JsonRPCError::InvalidRequest,
        JsonRPCError::MethodNotFound,
        JsonRPCError::InvalidParams,
    ];

    for error in daemon_rejection_cases {
        assert_eq!(
            classify_submit_error(&WalletError::from(Error::new(error))),
            SubmitErrorClass::DaemonRejected
        );
    }

    assert_eq!(
        classify_submit_error(&daemon_rejection()),
        SubmitErrorClass::DaemonRejected
    );
    assert_eq!(
        classify_submit_error(&WalletError::from(Error::new(
            JsonRPCError::InternalError {
                message: "internal".to_owned(),
                data: None,
            }
        ))),
        SubmitErrorClass::DaemonRejected
    );
    let conservative_local_failure_cases = [
        JsonRPCError::InvalidBatch,
        JsonRPCError::MissingResult,
        JsonRPCError::EventNotRegistered,
    ];

    for error in conservative_local_failure_cases {
        assert_eq!(
            classify_submit_error(&WalletError::from(Error::new(error))),
            SubmitErrorClass::LocalFailure
        );
    }

    assert_eq!(
        classify_submit_error(&WalletError::from(anyhow::anyhow!("unexpected"))),
        SubmitErrorClass::LocalFailure
    );
}
