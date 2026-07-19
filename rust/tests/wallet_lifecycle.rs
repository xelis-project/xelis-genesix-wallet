#![cfg(not(target_arch = "wasm32"))]

use std::sync::{Arc, RwLock};

use anyhow::Result;
use tempfile::tempdir;
use xelis_common::crypto::ecdlp::ECDLPTables;
use xelis_common::network::Network;
use xelis_wallet::precomputed_tables::PrecomputedTablesShared;
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
    assert!(reopened
        .get_storage()
        .read()
        .await
        .get_pending_txs()
        .is_empty());
    reopened.close().await;
    drop(reopened);

    Ok(())
}
