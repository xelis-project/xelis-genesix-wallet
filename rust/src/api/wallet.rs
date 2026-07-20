use flutter_rust_bridge::frb;

use std::sync::Arc;

use super::precomputed_tables::PrecomputedTableType;
use crate::multisig::PendingMultisigStore;
use anyhow::Result;
use futures::lock::Mutex as AsyncMutex;
use parking_lot::RwLock;
use xelis_common::network::Network;
use xelis_common::transaction::builder::{TransactionTypeBuilder, UnsignedTransaction};
use xelis_common::transaction::MultiSigPayload;
pub use xelis_common::transaction::Transaction;
pub use xelis_wallet::precomputed_tables::PrecomputedTablesShared;
pub use xelis_wallet::transaction_builder::TransactionBuilderState;
use xelis_wallet::wallet::Wallet;

mod amounts;
mod assets;
mod history;
mod multisig;
mod runtime;
mod transactions;

#[frb(ignore)]
struct PendingMultisigTransaction {
    unsigned: UnsignedTransaction,
    state: TransactionBuilderState,
    transaction_type: TransactionTypeBuilder,
    configuration: MultiSigPayload,
}

pub struct XelisWallet {
    wallet: Arc<Wallet>,
    asset_resolution: AsyncMutex<()>,
    prepared_transaction:
        RwLock<transactions::PreparedTransactionStore<(Transaction, TransactionBuilderState)>>,
    pending_multisig: RwLock<PendingMultisigStore<PendingMultisigTransaction>>,
}

#[frb(sync)]
pub fn refresh_mt_params() {
    runtime::refresh_mt_params()
}

#[frb(sync)]
pub fn set_mt_params(thread_count: usize, concurrency: usize) {
    runtime::set_mt_params(thread_count, concurrency)
}

#[frb(sync)]
pub fn clear_cached_tables() {
    runtime::clear_cached_tables()
}

#[frb(sync)]
pub fn drop_wallet(wallet: XelisWallet) {
    runtime::drop_wallet(wallet)
}

pub async fn update_tables(
    precomputed_tables_path: String,
    precomputed_table_type: PrecomputedTableType,
) -> Result<()> {
    runtime::update_tables(precomputed_tables_path, precomputed_table_type).await
}

pub fn get_current_precomputed_tables_type() -> Result<PrecomputedTableType> {
    runtime::get_current_precomputed_tables_type()
}

pub async fn create_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    seed: Option<String>,
    private_key: Option<String>,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> Result<XelisWallet> {
    runtime::create_xelis_wallet(
        name,
        directory,
        password,
        network,
        seed,
        private_key,
        precomputed_tables_path,
        precomputed_table_type,
    )
    .await
}

pub async fn open_xelis_wallet(
    name: String,
    directory: String,
    password: String,
    network: Network,
    precomputed_tables_path: Option<String>,
    precomputed_table_type: PrecomputedTableType,
) -> Result<XelisWallet> {
    runtime::open_xelis_wallet(
        name,
        directory,
        password,
        network,
        precomputed_tables_path,
        precomputed_table_type,
    )
    .await
}

impl XelisWallet {
    #[frb(ignore)]
    pub fn get_wallet(&self) -> &Arc<Wallet> {
        &self.wallet
    }

    pub fn clear_transaction(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        self.clear_transaction_internal(tx_hash)
    }
}
