use super::super::models::wallet_dtos::{SummaryTransaction, Transfer};
use super::{amounts, Transaction, TransactionBuilderState, XelisWallet};
use anyhow::{bail, Context, Result};
use log::{error, info, warn};
use serde_json::json;
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

impl XelisWallet {
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
        self.pending_transactions.write().clear();

        info!("Building transaction...");

        let transaction_type_builder = create_transfers(self, transfers)
            .await
            .context("Error while creating transaction type builder")?;

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
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
        log_transaction_context("Prepared transfer transaction", &tx, &state);

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        // TODO: add extra fee options
    ) -> Result<String> {
        self.pending_transactions.write().clear();

        info!("Building transfer all transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let mut amount = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        let address = Address::from_string(&str_address).context("Invalid address")?;

        let extra_data = match extra_data {
            None => None,
            Some(value) => Some(DataElement::Value(DataValue::String(value))),
        };

        let transfer = TransferBuilder {
            destination: address.clone(),
            amount,
            asset: asset.clone(),
            extra_data: extra_data.clone(),
            encrypt_extra_data: match encrypt_extra_data {
                Some(value) => value,
                None => true,
            },
        };

        let estimated_fees = self
            .wallet
            .estimate_fees(
                TransactionTypeBuilder::Transfers(vec![transfer]),
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        if asset == XELIS_ASSET {
            amount = amount
                .checked_sub(estimated_fees)
                .context("Insufficient balance for fees")?;
        }

        let transfer = TransferBuilder {
            destination: address,
            amount,
            asset: asset.clone(),

            extra_data,
            encrypt_extra_data: match encrypt_extra_data {
                Some(value) => value,
                None => true,
            },
        };

        let transaction_type_builder = TransactionTypeBuilder::Transfers(vec![transfer]);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
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
        log_transaction_context("Prepared transfer all transaction", &tx, &state);

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_burn_transaction(
        &self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<String> {
        self.pending_transactions.write().clear();

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

        let payload = BurnPayload {
            amount,
            asset: asset.clone(),
        };

        let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
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
        log_transaction_context("Prepared burn transaction", &tx, &state);

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub async fn create_burn_all_transaction(&self, asset_hash: String) -> Result<String> {
        self.pending_transactions.write().clear();

        info!("Building burn all transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let mut amount = {
            let storage = self.wallet.get_storage().read().await;
            storage.get_plaintext_balance_for(&asset).await?
        };

        info!("Burning all {} of {}", amount, asset);

        let mut payload = BurnPayload {
            amount,
            asset: asset.clone(),
        };

        let estimated_fees = self
            .wallet
            .estimate_fees(
                TransactionTypeBuilder::Burn(payload.clone()),
                FeeBuilder::default(),
                BaseFeeMode::None,
            )
            .await
            .context("Error while estimating fees")?;

        if asset == XELIS_ASSET {
            amount = amount
                .checked_sub(estimated_fees)
                .context("Insufficient balance to pay burn transaction fees")?;
            payload.amount = amount;
        }

        let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

        let (tx, state) = {
            let mut storage = self.wallet.get_storage().write().await;
            self.wallet
                .create_transaction_with_storage(
                    &mut storage,
                    transaction_type_builder.clone(),
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
        log_transaction_context("Prepared burn all transaction", &tx, &state);

        self.pending_transactions
            .write()
            .insert(hash.clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: hash.to_hex(),
            fee,
            transaction_type: transaction_type_builder
        })
        .to_string())
    }

    pub(super) fn clear_transaction_internal(
        &self,
        tx_hash: String,
    ) -> Result<(Transaction, TransactionBuilderState)> {
        let hash = Hash::from_hex(&tx_hash)?;
        let tx = self
            .pending_transactions
            .write()
            .remove(&hash)
            .context("Cannot delete pending transaction")?;

        info!("tx: {} removed from pending transaction", hash);
        Ok(tx)
    }

    pub async fn broadcast_transaction(&self, tx_hash: String) -> Result<()> {
        info!("start to broadcast tx: {}", tx_hash);

        if self.wallet.is_online().await {
            let (storage_tx_version, storage_topoheight, storage_top_block_hash) = {
                let storage = self.wallet.get_storage().read().await;
                (
                    storage.get_tx_version().await?,
                    storage.get_synced_topoheight()?,
                    storage.get_top_block_hash()?,
                )
            };
            let (tx, mut state) = self.clear_transaction_internal(tx_hash.clone())?;

            log_transaction_context("Broadcasting pending transaction", &tx, &state);
            info!(
            "Broadcast storage context: tx_hash={}, storage_tx_version={}, synced_topoheight={}, top_block_hash={}",
            tx_hash, storage_tx_version, storage_topoheight, storage_top_block_hash
        );
            self.log_daemon_context("Broadcast daemon context").await;

            info!("Broadcasting transaction...");
            if let Err(e) = self.wallet.submit_transaction(&tx).await {
                self.log_daemon_context("Broadcast failed daemon context")
                    .await;
                error!("Error while submitting transaction, clearing cache...");
                {
                    let mut storage = self.wallet.get_storage().write().await;
                    storage.clear_tx_cache().await;
                    storage.delete_unconfirmed_balances().await;
                }

                if is_retryable_submit_error(&e) {
                    warn!("Inserting back to pending transactions in case of retry...");
                    let hash: Hash = Hash::from_hex(&tx_hash)?;
                    self.pending_transactions.write().insert(hash, (tx, state));

                    bail!(e)
                }

                bail!(
                "Transaction was rejected by the daemon and cannot be retried safely. Please recreate the transaction. Cause: {}",
                e
            )
            } else {
                info!("Transaction submitted successfully!");
                let mut storage = self.wallet.get_storage().write().await;
                state
                    .apply_changes(&mut storage, self.wallet.as_ref(), &tx)
                    .await
                    .context("Error while applying changes")?;
                info!("Transaction applied to storage");
            }
        } else {
            bail!("Wallet is offline, transaction cannot be submitted");
        }

        Ok(())
    }
}

pub(super) async fn create_transfers(
    wallet: &XelisWallet,
    transfers: Vec<Transfer>,
) -> Result<TransactionTypeBuilder> {
    let mut vec = Vec::new();

    for transfer in transfers {
        let asset = Hash::from_hex(&transfer.asset_hash).context("Invalid asset")?;

        let amount = wallet
            .convert_float_amount(transfer.float_amount, &asset)
            .await
            .context("Error while converting amount to atomic format")?;

        let address = Address::from_string(&transfer.str_address).context("Invalid address")?;

        let transfer_builder = TransferBuilder {
            destination: address,
            amount,
            asset,
            extra_data: match transfer.extra_data {
                None => None,
                Some(value) => Some(DataElement::Value(DataValue::String(value))),
            },
            encrypt_extra_data: match transfer.encrypt_extra_data {
                Some(value) => value,
                None => true,
            },
        };

        vec.push(transfer_builder);
    }

    Ok(TransactionTypeBuilder::Transfers(vec))
}

impl XelisWallet {
    async fn convert_float_amount(&self, float_amount: f64, asset: &Hash) -> Result<u64> {
        let storage = self.wallet.get_storage().read().await;
        let decimals = storage.get_asset(&asset).await?.get_decimals();
        amounts::checked_atomic_amount(float_amount, decimals)
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

impl XelisWallet {
    async fn log_daemon_context(&self, action: &str) {
        let network_handler = self.wallet.get_network_handler().lock().await;
        let Some(handler) = network_handler.as_ref() else {
            warn!(
                "{}: daemon context unavailable, network handler missing",
                action
            );
            return;
        };

        match handler.get_api().get_info().await {
            Ok(info) => info!(
                "{}: daemon version={}, network={:?}, block_version={}, topoheight={}, stable_topoheight={}, top_block_hash={}, mempool_size={}",
                action,
                info.version,
                info.network,
                info.block_version,
                info.topoheight,
                info.stable_topoheight,
                info.top_block_hash,
                info.mempool_size
            ),
            Err(_) => warn!("{}: daemon context unavailable", action),
        }
    }
}

fn is_retryable_submit_error(error: &WalletError) -> bool {
    match error {
        WalletError::Any(error) => !is_daemon_rejection(error),
        WalletError::NotOnlineMode | WalletError::NoNetworkHandler => true,
        _ => false,
    }
}

fn is_daemon_rejection(error: &anyhow::Error) -> bool {
    matches!(
        error.downcast_ref::<JsonRPCError>(),
        Some(JsonRPCError::ServerError { .. })
    )
}
