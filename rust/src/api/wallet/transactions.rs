use super::super::models::wallet_dtos::{
    BroadcastTransactionOutcome, SummaryTransaction, Transfer,
};
use super::{amounts, Transaction, TransactionBuilderState, XelisWallet};
use anyhow::{bail, Context, Result};
use log::{error, info, warn};
use parking_lot::RwLock;
use serde_json::json;
use std::future::Future;
use std::mem;
use xelis_common::api::wallet::BaseFeeMode;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::{COIN_DECIMALS, XELIS_ASSET};
use xelis_common::crypto::{Address, Hash, Hashable};
use xelis_common::rpc::client::JsonRPCError;
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{FeeBuilder, TransactionTypeBuilder, TransferBuilder};
use xelis_common::transaction::BurnPayload;
use xelis_common::utils::format_coin;
use xelis_wallet::error::WalletError;

enum SubmissionResolution {
    Submitted,
    Retryable(WalletError),
    DaemonRejected(WalletError),
    LocalFailure(WalletError),
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum SubmitErrorClass {
    Retryable,
    DaemonRejected,
    LocalFailure,
}

enum PreparedTransactionState<T> {
    Empty,
    Ready { hash: Hash, transaction: T },
    InFlight { hash: Hash },
}

impl<T> Default for PreparedTransactionState<T> {
    fn default() -> Self {
        Self::Empty
    }
}

pub(super) struct PreparedTransactionStore<T> {
    state: PreparedTransactionState<T>,
}

impl<T> Default for PreparedTransactionStore<T> {
    fn default() -> Self {
        Self {
            state: PreparedTransactionState::Empty,
        }
    }
}

impl<T> PreparedTransactionStore<T> {
    pub(super) fn ensure_replaceable(&self) -> Result<()> {
        if matches!(self.state, PreparedTransactionState::InFlight { .. }) {
            bail!(
                "Cannot replace a prepared transaction while another transaction is being submitted"
            );
        }

        Ok(())
    }

    pub(super) fn replace(&mut self, hash: Hash, transaction: T) -> Result<()> {
        self.ensure_replaceable()?;
        self.state = PreparedTransactionState::Ready { hash, transaction };
        Ok(())
    }

    fn cancel(&mut self, hash: &Hash) -> Result<T> {
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
            } if submitted_hash == hash => {
                bail!("Cannot cancel a transaction while it is being submitted")
            }
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                ..
            } if prepared_hash == hash => {}
            _ => bail!("Cannot delete prepared transaction"),
        }

        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready { transaction, .. } => Ok(transaction),
            previous_state => {
                self.state = previous_state;
                bail!("Prepared transaction state changed during cancellation")
            }
        }
    }

    fn take_for_submission(&mut self, hash: &Hash) -> Result<T> {
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
            } if submitted_hash == hash => {
                bail!("Transaction is already being submitted")
            }
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                ..
            } if prepared_hash == hash => {}
            _ => bail!("Cannot find prepared transaction"),
        }

        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                transaction,
            } => {
                self.state = PreparedTransactionState::InFlight {
                    hash: prepared_hash,
                };
                Ok(transaction)
            }
            previous_state => {
                self.state = previous_state;
                bail!("Prepared transaction state changed before submission")
            }
        }
    }

    fn restore_after_submission(&mut self, hash: Hash, transaction: T) -> Result<()> {
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
            } if submitted_hash == &hash => {
                self.state = PreparedTransactionState::Ready { hash, transaction };
                Ok(())
            }
            _ => bail!("Prepared transaction submission state is inconsistent"),
        }
    }

    fn finish_submission(&mut self, hash: &Hash) -> bool {
        if matches!(
            &self.state,
            PreparedTransactionState::InFlight {
                hash: submitted_hash
            } if submitted_hash == hash
        ) {
            self.state = PreparedTransactionState::Empty;
            true
        } else {
            false
        }
    }
}

struct PreparedTransactionGuard<'a, T> {
    store: &'a RwLock<PreparedTransactionStore<T>>,
    hash: Hash,
    transaction: Option<T>,
}

impl<'a, T> PreparedTransactionGuard<'a, T> {
    fn take(store: &'a RwLock<PreparedTransactionStore<T>>, hash: Hash) -> Result<Self> {
        let transaction = store.write().take_for_submission(&hash)?;
        Ok(Self {
            store,
            hash,
            transaction: Some(transaction),
        })
    }

    fn transaction(&self) -> Result<&T> {
        self.transaction
            .as_ref()
            .context("Prepared transaction guard is empty")
    }

    fn restore(mut self) -> Result<()> {
        let transaction = self
            .transaction
            .take()
            .context("Prepared transaction guard is empty")?;
        self.store
            .write()
            .restore_after_submission(self.hash.clone(), transaction)
    }

    fn finish(mut self) -> Result<T> {
        let transaction = self
            .transaction
            .take()
            .context("Prepared transaction guard is empty")?;

        if !self.store.write().finish_submission(&self.hash) {
            self.transaction = Some(transaction);
            bail!("Prepared transaction submission state is inconsistent");
        }

        Ok(transaction)
    }
}

impl<T> Drop for PreparedTransactionGuard<'_, T> {
    fn drop(&mut self) {
        if let Some(transaction) = self.transaction.take() {
            if let Err(error) = self
                .store
                .write()
                .restore_after_submission(self.hash.clone(), transaction)
            {
                error!(
                    "Prepared transaction could not be restored after an interrupted submission: {error}"
                );
            } else {
                warn!(
                    "Prepared transaction {} restored after an interrupted submission",
                    self.hash
                );
            }
        }
    }
}

fn ensure_wallet_online(is_online: bool) -> Result<()> {
    if !is_online {
        bail!("Wallet is offline, transaction cannot be submitted");
    }

    Ok(())
}

fn resolve_submission(submit_result: std::result::Result<(), WalletError>) -> SubmissionResolution {
    match submit_result {
        Ok(()) => SubmissionResolution::Submitted,
        Err(error) => match classify_submit_error(&error) {
            SubmitErrorClass::Retryable => SubmissionResolution::Retryable(error),
            SubmitErrorClass::DaemonRejected => SubmissionResolution::DaemonRejected(error),
            SubmitErrorClass::LocalFailure => SubmissionResolution::LocalFailure(error),
        },
    }
}

pub(super) fn encrypt_extra_data_or_default(value: Option<bool>) -> bool {
    value.unwrap_or(true)
}

pub(super) fn amount_after_fee(
    amount: u64,
    fee: u64,
    asset: &Hash,
    insufficient_funds_context: &'static str,
) -> Result<u64> {
    let amount = if asset == &XELIS_ASSET {
        amount
            .checked_sub(fee)
            .context(insufficient_funds_context)?
    } else {
        amount
    };

    (amount > 0)
        .then_some(amount)
        .context(insufficient_funds_context)
}

pub(super) fn build_transfer(
    destination: Address,
    amount: u64,
    asset: Hash,
    extra_data: Option<String>,
    encrypt_extra_data: Option<bool>,
) -> TransferBuilder {
    TransferBuilder {
        destination,
        amount,
        asset,
        extra_data: extra_data.map(|value| DataElement::Value(DataValue::String(value))),
        encrypt_extra_data: encrypt_extra_data_or_default(encrypt_extra_data),
    }
}

fn build_transfer_from_input(
    transfer: Transfer,
    asset: Hash,
    decimals: u8,
) -> Result<TransferBuilder> {
    let amount = amounts::checked_atomic_amount(transfer.float_amount, decimals)
        .context("Error while converting amount to atomic format")?;
    let destination = Address::from_string(&transfer.str_address).context("Invalid address")?;

    Ok(build_transfer(
        destination,
        amount,
        asset,
        transfer.extra_data,
        transfer.encrypt_extra_data,
    ))
}

fn build_transfer_all_type(
    destination: Address,
    balance: u64,
    fee: u64,
    asset: Hash,
    extra_data: Option<String>,
    encrypt_extra_data: Option<bool>,
) -> Result<TransactionTypeBuilder> {
    let amount = amount_after_fee(balance, fee, &asset, "Insufficient balance for fees")?;
    let transfer = build_transfer(destination, amount, asset, extra_data, encrypt_extra_data);

    Ok(TransactionTypeBuilder::Transfers(vec![transfer]))
}

fn build_burn_type(asset: Hash, amount: u64) -> TransactionTypeBuilder {
    TransactionTypeBuilder::Burn(BurnPayload { amount, asset })
}

fn build_burn_all_type(asset: Hash, balance: u64, fee: u64) -> Result<TransactionTypeBuilder> {
    let amount = amount_after_fee(
        balance,
        fee,
        &asset,
        "Insufficient balance to pay burn transaction fees",
    )?;

    Ok(build_burn_type(asset, amount))
}

fn transaction_summary_json(
    hash: &Hash,
    fee: u64,
    transaction_type: TransactionTypeBuilder,
) -> String {
    json!(SummaryTransaction {
        hash: hash.to_hex(),
        fee,
        transaction_type,
    })
    .to_string()
}

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
}

pub(super) async fn create_transfers(
    wallet: &XelisWallet,
    transfers: Vec<Transfer>,
) -> Result<TransactionTypeBuilder> {
    create_transfers_with_decimals(transfers, |asset| async move {
        let storage = wallet.wallet.get_storage().read().await;
        Ok(storage.get_asset(&asset).await?.get_decimals())
    })
    .await
}

async fn create_transfers_with_decimals<LoadDecimals, LoadDecimalsFuture>(
    transfers: Vec<Transfer>,
    mut load_decimals: LoadDecimals,
) -> Result<TransactionTypeBuilder>
where
    LoadDecimals: FnMut(Hash) -> LoadDecimalsFuture,
    LoadDecimalsFuture: Future<Output = Result<u8>>,
{
    let mut vec = Vec::new();

    for transfer in transfers {
        let asset = Hash::from_hex(&transfer.asset_hash).context("Invalid asset")?;
        let decimals = load_decimals(asset.clone())
            .await
            .context("Error while converting amount to atomic format")?;
        let transfer_builder = build_transfer_from_input(transfer, asset, decimals)?;

        vec.push(transfer_builder);
    }

    Ok(TransactionTypeBuilder::Transfers(vec))
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

impl XelisWallet {
    async fn clear_unconfirmed_transaction_state(&self) {
        let mut storage = self.wallet.get_storage().write().await;
        storage.delete_unconfirmed_balances().await;
    }
}

fn is_daemon_rejection(error: &anyhow::Error) -> bool {
    matches!(
        error.downcast_ref::<JsonRPCError>(),
        Some(
            JsonRPCError::ParseError
                | JsonRPCError::InvalidRequest
                | JsonRPCError::MethodNotFound
                | JsonRPCError::InvalidParams
                | JsonRPCError::InternalError { .. }
                | JsonRPCError::ServerError { .. }
        )
    )
}

fn is_retryable_rpc_error(error: &anyhow::Error) -> bool {
    matches!(
        error.downcast_ref::<JsonRPCError>(),
        Some(
            JsonRPCError::NoResponse(_, _)
                | JsonRPCError::TimedOut(_)
                | JsonRPCError::HttpError(_)
                | JsonRPCError::ConnectionError(_)
                | JsonRPCError::SocketError(_)
                | JsonRPCError::SendError(_, _)
        )
    )
}

fn classify_submit_error(error: &WalletError) -> SubmitErrorClass {
    // Retain the prepared transaction only for explicitly known transport or
    // offline failures. New or wrapped error variants must remain final until
    // their retry semantics have been reviewed.
    match error {
        WalletError::Any(error) if is_retryable_rpc_error(error) => SubmitErrorClass::Retryable,
        WalletError::Any(error) if is_daemon_rejection(error) => SubmitErrorClass::DaemonRejected,
        WalletError::NotOnlineMode | WalletError::NoNetworkHandler => SubmitErrorClass::Retryable,
        _ => SubmitErrorClass::LocalFailure,
    }
}

#[cfg(test)]
mod tests;
