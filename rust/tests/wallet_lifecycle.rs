#![cfg(not(target_arch = "wasm32"))]

use std::sync::{Arc, RwLock};

use anyhow::Result;
use tempfile::tempdir;
use xelis_common::crypto::{ecdlp::ECDLPTables, Hash};
use xelis_common::network::Network;
use xelis_wallet::entry::{EntryData, TransactionEntry};
use xelis_wallet::precomputed_tables::PrecomputedTablesShared;
use xelis_wallet::storage::TransactionFilterOptions;
use xelis_wallet::wallet::{RecoverOption, Wallet};

#[tokio::test]
#[ignore = "uses production Argon2 parameters; run explicitly as the slow wallet lifecycle test"]
async fn wallet_can_be_created_reopened_and_rejects_a_wrong_password() -> Result<()> {
    let directory = tempdir()?;
    let wallet_path = directory.path().join("wallet");
    let wallet_path = wallet_path.to_string_lossy().into_owned();
    let password = "integration-test-password";
    let network = Network::Devnet;
    let tables: PrecomputedTablesShared = Arc::new(RwLock::new(ECDLPTables::empty(1)));

    let wallet = Wallet::create(
        &wallet_path,
        password,
        RecoverOption::None,
        network,
        tables.clone(),
        1,
        1,
    )
    .await?;
    let address = wallet.get_address().to_string();
    assert!(wallet
        .get_storage()
        .read()
        .await
        .get_pending_txs()
        .is_empty());

    let earlier_hash = Hash::new([1; 32]);
    let later_hash = Hash::new([2; 32]);
    {
        let mut storage = wallet.get_storage().write().await;
        storage.save_transaction(
            &later_hash,
            &TransactionEntry::new(
                later_hash.clone(),
                20,
                2_000,
                EntryData::Coinbase { reward: 200_000 },
            ),
        )?;
        storage.save_transaction(
            &earlier_hash,
            &TransactionEntry::new(
                earlier_hash.clone(),
                10,
                1_000,
                EntryData::Coinbase { reward: 100_000 },
            ),
        )?;
    }

    {
        let storage = wallet.get_storage().read().await;
        let transactions = storage.get_filtered_transactions(TransactionFilterOptions::default())?;
        let mut csv = Vec::new();
        wallet
            .export_transactions_in_csv(&storage, transactions, &mut csv)
            .await?;

        let csv = String::from_utf8(csv)?;
        let lines = csv.lines().collect::<Vec<_>>();
        assert_eq!(
            lines[0],
            "Date,TopoHeight,Hash,Type,From/To,Asset,Amount,Fee,Nonce"
        );
        assert_eq!(lines.len(), 3);
        assert!(lines[1].contains(&format!(",10,{earlier_hash},Coinbase,XELIS,-,")));
        assert!(lines[1].ends_with(",Coinbase,XELIS,-,0.00100000,-,-"));
        assert!(lines[2].contains(&format!(",20,{later_hash},Coinbase,XELIS,-,")));
        assert!(lines[2].ends_with(",Coinbase,XELIS,-,0.00200000,-,-"));

        let filtered = storage.get_filtered_transactions(TransactionFilterOptions {
            min_topoheight: Some(15),
            ..Default::default()
        })?;
        let mut filtered_csv = Vec::new();
        wallet
            .export_transactions_in_csv(&storage, filtered, &mut filtered_csv)
            .await?;
        let filtered_csv = String::from_utf8(filtered_csv)?;
        assert!(!filtered_csv.contains(&earlier_hash.to_string()));
        assert!(filtered_csv.contains(&later_hash.to_string()));
    }

    wallet.close().await;
    drop(wallet);

    assert!(Wallet::open(
        &wallet_path,
        "wrong-password",
        network,
        tables.clone(),
        1,
        1,
    )
    .is_err());

    let reopened = Wallet::open(&wallet_path, password, network, tables, 1, 1)?;
    assert_eq!(reopened.get_address().to_string(), address);
    assert_eq!(*reopened.get_network(), network);
    {
        let storage = reopened.get_storage().read().await;
        assert!(storage.get_pending_txs().is_empty());
        assert_eq!(storage.get_transactions_count()?, 2);
    }
    reopened.close().await;
    drop(reopened);

    Ok(())
}
