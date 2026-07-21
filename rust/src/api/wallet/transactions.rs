use super::super::models::wallet_dtos::{BroadcastTransactionOutcome, Transfer};
use super::{amounts, Transaction, TransactionBuilderState, XelisWallet};
use anyhow::{Context, Result};
use log::{error, info};
use parking_lot::RwLock;
use std::future::Future;
use xelis_common::api::wallet::BaseFeeMode;
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{Address, Hash, Hashable};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{FeeBuilder, TransactionTypeBuilder};
use xelis_common::utils::format_coin;

mod builders;
mod prepared;
mod submission;

pub(super) use builders::{amount_after_fee, build_transfer, create_transfers};
use builders::{
    build_burn_all_type, build_burn_type, build_transfer_all_type, transaction_summary_json,
};
use prepared::PreparedTransactionGuard;
pub(super) use prepared::PreparedTransactionStore;
use submission::{ensure_wallet_online, resolve_submission, SubmissionResolution};

async fn build_and_store_prepared<T, Build, BuildFuture>(
    store: &RwLock<PreparedTransactionStore<T>>,
    transaction_type: TransactionTypeBuilder,
    build: Build,
) -> Result<String>
where
    Build: FnOnce(TransactionTypeBuilder) -> BuildFuture,
    BuildFuture: Future<Output = Result<(Hash, u64, T)>>,
{
    let (hash, fee, prepared) = build(transaction_type.clone()).await?;
    let summary = transaction_summary_json(&hash, fee, transaction_type);
    store.write().replace(hash, prepared)?;

    Ok(summary)
}

impl XelisWallet {
    async fn create_and_store_prepared_transaction(
        &self,
        transaction_type: TransactionTypeBuilder,
        action: &'static str,
    ) -> Result<String> {
        build_and_store_prepared(
            &self.prepared_transaction,
            transaction_type,
            |transaction_type| async move {
                let (tx, state) = {
                    let mut storage = self.wallet.get_storage().write().await;
                    self.wallet
                        .create_transaction_with_storage(
                            &mut storage,
                            transaction_type,
                            FeeBuilder::default(),
                            BaseFeeMode::None,
                            None,
                        )
                        .await?
                };

                info!("Transaction created!");
                let hash = tx.hash();
                info!("Tx Hash: {}", hash);
                let fee = tx.get_fee();
                log_transaction_context(action, &tx, &state);

                Ok((hash, fee, (tx, state)))
            },
        )
        .await
    }

    pub async fn estimate_fees(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
        let transaction_type_builder = create_transfers(self, transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                transaction_type_builder,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        Ok(format_coin(estimated_fees, COIN_DECIMALS))
    }

    pub async fn create_transfers_transaction(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<String> {
        info!("Building transaction...");

        let transaction_type_builder = create_transfers(self, transfers)
            .await
            .context("Error while creating transaction type builder")?;

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared transfer transaction",
        )
        .await
    }

    pub async fn create_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        // TODO: add extra fee options
    ) -> Result<String> {
        info!("Building transfer all transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        let address = Address::from_string(&str_address).context("Invalid address")?;

        let estimated_transaction_type = build_transfer_all_type(
            address.clone(),
            balance,
            0,
            asset.clone(),
            extra_data.clone(),
            encrypt_extra_data,
        )?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                estimated_transaction_type,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        let transaction_type_builder = build_transfer_all_type(
            address,
            balance,
            estimated_fees,
            asset,
            extra_data,
            encrypt_extra_data,
        )?;

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared transfer all transaction",
        )
        .await
    }

    pub async fn create_burn_transaction(
        &self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        info!("Building burn transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (amount, decimals) = {
            let storage = self.wallet.get_storage().read().await;
            let decimals = storage
                .get_asset(&asset)
                .await
                .context("Asset not found in storage")?
                .get_decimals();
            let amount = amounts::checked_atomic_amount(float_amount, decimals)?;
            (amount, decimals)
        };

        info!("Burning {} of {}", format_coin(amount, decimals), asset);

        let transaction_type_builder = build_burn_type(asset, amount);

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared burn transaction",
        )
        .await
    }

    pub async fn create_burn_all_transaction(&self, asset_hash: String) -> Result<String> {
        info!("Building burn all transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        info!("Burning all {} of {}", balance, asset);

        let estimated_transaction_type = build_burn_all_type(asset.clone(), balance, 0)?;

        let estimated_fees = self
            .wallet
            .estimate_fees(
                estimated_transaction_type,
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        let transaction_type_builder = build_burn_all_type(asset, balance, estimated_fees)?;

        self.create_and_store_prepared_transaction(
            transaction_type_builder,
            "Prepared burn all transaction",
        )
        .await
    }

    pub(super) fn clear_transaction_internal(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        let hash = Hash::from_hex(&tx_hash)?;
        let tx = self.prepared_transaction.write().cancel(&hash)?;

        info!("tx: {} removed from prepared transaction", hash);
        Ok(tx)
    }

    pub(super) fn replace_prepared_transaction(
        &self,
        hash: Hash,
        transaction: Transaction,
        state: TransactionBuilderState,
    ) -> Result<()> {
        self.prepared_transaction
            .write()
            .replace(hash, (transaction, state))
    }

    pub async fn broadcast_transaction(
        &self,
        tx_hash: String,
    ) -> Result<BroadcastTransactionOutcome> {
        info!("start to broadcast tx: {}", tx_hash);

        ensure_wallet_online(self.wallet.is_online().await)?;

        let (storage_tx_version, storage_topoheight, storage_top_block_hash) = {
            let storage = self.wallet.get_storage().read().await;
            (
                storage.get_tx_version().await?,
                storage.get_synced_topoheight()?,
                storage.get_top_block_hash()?,
            )
        };
        let hash = Hash::from_hex(&tx_hash)?;
        let prepared_transaction =
            PreparedTransactionGuard::take(&self.prepared_transaction, hash.clone())?;
        let (tx, state) = prepared_transaction.transaction()?;

        log_transaction_context("Broadcasting prepared transaction", tx, state);
        info!(
            "Broadcast storage context: tx_hash={}, storage_tx_version={}, synced_topoheight={}, top_block_hash={}",
            tx_hash, storage_tx_version, storage_topoheight, storage_top_block_hash
        );

        info!("Broadcasting transaction...");
        let submit_result = self.wallet.submit_transaction(tx).await;
        let resolution = resolve_submission(submit_result);

        match resolution {
            SubmissionResolution::Submitted => {
                let (tx, mut state) = prepared_transaction.finish()?;
                info!("Transaction submitted successfully!");
                let mut storage = self.wallet.get_storage().write().await;
                if let Err(error) = state
                    .apply_changes(&mut storage, self.wallet.as_ref(), &tx)
                    .await
                {
                    error!(
                        "Transaction was submitted but local state application failed: kind={}",
                        error.kind()
                    );
                    storage.delete_unconfirmed_balances().await;
                    return Ok(BroadcastTransactionOutcome::SubmittedNeedsResync);
                }
                info!("Transaction applied to storage");
                Ok(BroadcastTransactionOutcome::Submitted)
            }
            SubmissionResolution::Retryable(error) => {
                let kind = error.kind();
                prepared_transaction.restore()?;
                error!("Retryable transaction submission failure: kind={kind}");
                self.clear_unconfirmed_transaction_state().await;
                Ok(BroadcastTransactionOutcome::Retryable)
            }
            SubmissionResolution::DaemonRejected(error) => {
                let kind = error.kind();
                let _discarded = prepared_transaction.finish()?;
                error!("Daemon rejected transaction submission: kind={kind}");
                self.clear_unconfirmed_transaction_state().await;
                Ok(BroadcastTransactionOutcome::Rejected)
            }
            SubmissionResolution::LocalFailure(error) => {
                let kind = error.kind();
                let _discarded = prepared_transaction.finish()?;
                error!("Local transaction submission failure: kind={kind}");
                self.clear_unconfirmed_transaction_state().await;
                Ok(BroadcastTransactionOutcome::LocalFailure)
            }
        }
    }

    async fn clear_unconfirmed_transaction_state(&self) {
        let mut storage = self.wallet.get_storage().write().await;
        storage.delete_unconfirmed_balances().await;
    }
}

pub(super) fn log_transaction_context(
    action: &str,
    tx: &Transaction,
    state: &TransactionBuilderState,
) {
    let tx_reference = tx.get_reference();
    let state_reference = state.get_reference();

    info!(
        "{}: hash={}, nonce={}, tx_version={}, tx_ref=({}, {}), state_nonce={}, state_ref=({}, {})",
        action,
        tx.hash(),
        tx.get_nonce(),
        tx.get_version(),
        tx_reference.topoheight,
        tx_reference.hash,
        state.get_nonce(),
        state_reference.topoheight,
        state_reference.hash
    );
}

#[cfg(test)]
mod tests;
