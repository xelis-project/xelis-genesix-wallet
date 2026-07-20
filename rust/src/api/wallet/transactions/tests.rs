use std::sync::{Arc, Barrier};
use std::thread;

use anyhow::Error;
use parking_lot::RwLock;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Hash, KeyPair};
use xelis_common::rpc::client::JsonRPCError;
use xelis_wallet::error::WalletError;

use crate::api::models::wallet_dtos::BroadcastTransactionOutcome;

use super::{
    amount_after_fee, build_transfer, classify_submit_error, encrypt_extra_data_or_default,
    ensure_wallet_online, is_daemon_rejection, resolve_submission, PreparedTransactionGuard,
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
    let error = amount_after_fee(24, 25, &XELIS_ASSET, "insufficient").unwrap_err();

    assert_eq!(error.to_string(), "insufficient");
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
