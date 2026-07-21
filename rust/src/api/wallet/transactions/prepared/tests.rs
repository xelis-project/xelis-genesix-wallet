use std::sync::{Arc, Barrier};
use std::thread;

use parking_lot::RwLock;
use xelis_common::crypto::Hash;

use super::*;

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
