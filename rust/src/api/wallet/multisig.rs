use std::borrow::Cow;

use super::super::models::wallet_dtos::{
    MultisigDartPayload, MultisigSignatureShare, MultisigSigningRequest, ParticipantDartPayload,
    SummaryTransaction, Transfer,
};
use super::{
    amounts, transactions, PendingMultisigTransaction, TransactionBuilderState, XelisWallet,
};
use crate::multisig::{
    build_verified_multisig, create_multisig_signature_share, create_multisig_signing_request,
    parse_multisig_signature_share, parse_multisig_signing_request, validate_multisig_setup,
    ParsedMultisigSigningRequest,
};
use anyhow::{bail, Context, Result};
use flutter_rust_bridge::frb;
use indexmap::IndexSet;
use log::{info, warn};
use serde_json::json;
use xelis_common::api::daemon::{GetMultisigParams, GetMultisigResult, MultisigState};
use xelis_common::api::wallet::BaseFeeMode;
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Address, Hash, Hashable, PublicKey};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{
    FeeBuilder, MultiSigBuilder, TransactionTypeBuilder, UnsignedTransaction,
};
use xelis_common::transaction::{BurnPayload, MultiSigPayload};
use xelis_common::utils::format_coin;

fn is_multisig_participant_address_valid(
    address: &Address,
    mainnet: bool,
    wallet_public_key: &PublicKey,
) -> bool {
    address.is_normal()
        && address.is_mainnet() == mainnet
        && address.get_public_key() != wallet_public_key
}

fn parse_multisig_participants(
    participants: Vec<String>,
    mainnet: bool,
    wallet_public_key: &PublicKey,
) -> Result<IndexSet<Address>> {
    let mut participant_addresses = IndexSet::with_capacity(participants.len());

    for participant in participants {
        let Ok(address) = Address::from_string(&participant) else {
            bail!("Invalid multisig participant address");
        };
        if !is_multisig_participant_address_valid(&address, mainnet, wallet_public_key) {
            bail!("Invalid multisig participant address");
        }
        if !participant_addresses.insert(address) {
            bail!("A multisig participant was provided more than once");
        }
    }

    Ok(participant_addresses)
}

impl XelisWallet {
    pub async fn create_multisig_transfers_transaction(
        &self,
        transfers: Vec<Transfer>,
        // TODO: add extra fee options
    ) -> Result<MultisigSigningRequest> {
        info!("Building transaction...");

        let multisig = {
            let storage = self.wallet.get_storage().read().await;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            multisig.cloned()
        };

        match multisig {
            Some(multisig) => {
                let transaction_type_builder = transactions::create_transfers(self, transfers)
                    .await
                    .context("Error while creating transaction type builder")?;

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                self.store_pending_multisig_transaction(
                    unsigned,
                    state,
                    transaction_type_builder,
                    multisig.payload,
                )
            }
            None => {
                bail!("No multisig configured");
            }
        }
    }

    pub async fn create_multisig_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        // TODO: add extra fee options
    ) -> Result<MultisigSigningRequest> {
        info!("Building multisig transfer all transaction...");

        let asset = match asset_hash {
            None => XELIS_ASSET,
            Some(value) => Hash::from_hex(&value).context("Invalid asset")?,
        };

        let (mut amount, multisig) = {
            let storage = self.wallet.get_storage().read().await;
            let amount = storage.get_plaintext_balance_for(&asset).await?;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            (amount, multisig.cloned())
        };

        match multisig {
            Some(multisig) => {
                let address = Address::from_string(&str_address).context("Invalid address")?;

                let transfer = transactions::build_transfer(
                    address.clone(),
                    amount,
                    asset.clone(),
                    extra_data.clone(),
                    encrypt_extra_data,
                );

                let estimated_fees = self
                    .wallet
                    .estimate_fees(
                        TransactionTypeBuilder::Transfers(vec![transfer]),
                        FeeBuilder::default(),
                        BaseFeeMode::None,
                    )
                    .await
                    .context("Error while estimating fees")?;

                amount = transactions::amount_after_fee(
                    amount,
                    estimated_fees,
                    &asset,
                    "Insufficient balance for fees",
                )?;

                let transfer = transactions::build_transfer(
                    address,
                    amount,
                    asset.clone(),
                    extra_data,
                    encrypt_extra_data,
                );

                let transaction_type_builder = TransactionTypeBuilder::Transfers(vec![transfer]);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                self.store_pending_multisig_transaction(
                    unsigned,
                    state,
                    transaction_type_builder,
                    multisig.payload,
                )
            }
            None => {
                bail!("No multisig configured");
            }
        }
    }

    pub async fn create_multisig_burn_transaction(
        &self,
        float_amount: f64,
        asset_hash: String,
    ) -> Result<MultisigSigningRequest> {
        info!("Building burn transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (amount, decimals, multisig) = {
            let storage = self.wallet.get_storage().read().await;
            let decimals = storage
                .get_asset(&asset)
                .await
                .context("Asset not found in storage")?
                .get_decimals();
            let amount = amounts::checked_atomic_amount(float_amount, decimals)?;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            (amount, decimals, multisig.cloned())
        };

        match multisig {
            Some(multisig) => {
                info!("Burning {} of {}", format_coin(amount, decimals), asset);

                let payload = BurnPayload {
                    amount,
                    asset: asset.clone(),
                };

                let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                self.store_pending_multisig_transaction(
                    unsigned,
                    state,
                    transaction_type_builder,
                    multisig.payload,
                )
            }
            None => {
                bail!("No multisig configured");
            }
        }
    }

    pub async fn create_multisig_burn_all_transaction(
        &self,
        asset_hash: String,
    ) -> Result<MultisigSigningRequest> {
        info!("Building burn all transaction...");

        let asset = Hash::from_hex(&asset_hash).context("Invalid asset")?;

        let (mut amount, multisig) = {
            let storage = self.wallet.get_storage().read().await;
            let amount = storage.get_plaintext_balance_for(&asset).await?;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            (amount, multisig.cloned())
        };

        match multisig {
            Some(multisig) => {
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

                amount = transactions::amount_after_fee(
                    amount,
                    estimated_fees,
                    &asset,
                    "Insufficient balance to pay burn transaction fees",
                )?;
                payload.amount = amount;

                let transaction_type_builder = TransactionTypeBuilder::Burn(payload);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                self.store_pending_multisig_transaction(
                    unsigned,
                    state,
                    transaction_type_builder,
                    multisig.payload,
                )
            }
            None => {
                bail!("No multisig configured");
            }
        }
    }

    pub async fn get_multisig_state(&self) -> Result<Option<String>> {
        let storage = self.wallet.get_storage().read().await;
        let multisig = storage
            .get_multisig_state()
            .await
            .context("Error while reading multisig state")?;
        match multisig {
            Some(multisig) => Ok(Some(
                json!(MultisigDartPayload {
                    threshold: multisig.payload.threshold,
                    participants: multisig
                        .payload
                        .participants
                        .iter()
                        .enumerate()
                        .map(|(i, p)| {
                            ParticipantDartPayload {
                                id: i as u8,
                                address: p
                                    .as_address(self.wallet.get_network().is_mainnet())
                                    .to_string(),
                            }
                        })
                        .collect::<Vec<_>>(),
                    topoheight: multisig.topoheight
                })
                .to_string(),
            )),
            None => Ok(None),
        }
    }

    pub async fn multisig_setup(&self, threshold: u8, participants: Vec<String>) -> Result<String> {
        info!("Setting up multisig...");
        validate_multisig_setup(threshold, participants.len())?;

        let multisig = {
            let storage = self.wallet.get_storage().read().await;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            multisig.cloned()
        };

        match multisig {
            Some(_multisig) => {
                bail!("Multisig already configured");
            }
            None => {
                let participant_addresses = parse_multisig_participants(
                    participants,
                    self.wallet.get_network().is_mainnet(),
                    self.wallet.get_public_key(),
                )?;

                let payload = MultiSigBuilder {
                    participants: participant_addresses,
                    threshold,
                };
                let transaction_type_builder = TransactionTypeBuilder::MultiSig(payload);

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
                transactions::log_transaction_context(
                    "Prepared multisig setup transaction",
                    &tx,
                    &state,
                );

                self.pending_transactions
                    .write()
                    .insert(hash.clone(), (tx, state));

                Ok(json!(SummaryTransaction {
                    hash: hash.to_hex(),
                    fee,
                    transaction_type: transaction_type_builder
                })
                .to_string())
            }
        }
    }

    #[frb(sync)]
    pub fn is_address_valid_for_multisig(&self, address: String) -> Result<bool> {
        let address = match Address::from_string(&address) {
            Ok(address) => address,
            Err(_) => {
                warn!("Invalid address");
                return Ok(false);
            }
        };

        let mainnet = self.wallet.get_network().is_mainnet();
        Ok(is_multisig_participant_address_valid(
            &address,
            mainnet,
            self.wallet.get_public_key(),
        ))
    }

    pub async fn init_delete_multisig(&self) -> Result<MultisigSigningRequest> {
        info!("Deleting multisig...");
        let multisig = {
            let storage = self.wallet.get_storage().read().await;
            let multisig = storage
                .get_multisig_state()
                .await
                .context("Error while reading multisig state")?;
            multisig.cloned()
        };

        match multisig {
            Some(multisig) => {
                let payload = MultiSigBuilder {
                    participants: IndexSet::new(),
                    threshold: 0,
                };

                let transaction_type_builder = TransactionTypeBuilder::MultiSig(payload);

                let (unsigned, state) = self
                    .build_unsigned_transaction(
                        transaction_type_builder.clone(),
                        FeeBuilder::default(),
                        multisig.payload.threshold,
                    )
                    .await?;

                self.store_pending_multisig_transaction(
                    unsigned,
                    state,
                    transaction_type_builder,
                    multisig.payload,
                )
            }
            None => bail!("No multisig configured"),
        }
    }

    pub async fn finalize_multisig_transaction(
        &self,
        tx_hash: String,
        signature_shares: Vec<String>,
    ) -> Result<String> {
        let expected_hash = Hash::from_hex(&tx_hash).context("Invalid multisig request hash")?;
        let signatures = signature_shares
            .iter()
            .map(|share| parse_multisig_signature_share(share, &expected_hash))
            .collect::<Result<Vec<_>>>()?;
        let (pending, multisig) = self
            .pending_multisig
            .write()
            .take_validated(&expected_hash, |pending| {
                build_verified_multisig(&expected_hash, &pending.configuration, &signatures)
            })?;

        let PendingMultisigTransaction {
            mut unsigned,
            state,
            transaction_type: transaction_type_builder,
            ..
        } = pending;

        unsigned.set_multisig(multisig);

        let tx = unsigned.finalize(self.wallet.get_keypair());
        transactions::log_transaction_context(
            "Prepared finalized multisig transaction",
            &tx,
            &state,
        );

        self.pending_transactions
            .write()
            .insert(tx.hash().clone(), (tx.clone(), state));

        Ok(json!(SummaryTransaction {
            hash: tx.hash().to_hex(),
            fee: tx.get_fee(),
            transaction_type: transaction_type_builder,
        })
        .to_string())
    }

    #[frb(sync)]
    pub fn get_pending_multisig_request_hash(&self) -> Option<String> {
        self.pending_multisig
            .read()
            .hash()
            .map(|hash| hash.to_hex())
    }

    #[frb(sync)]
    pub fn cancel_pending_multisig_request(&self, tx_hash: String) -> Result<()> {
        let expected_hash = Hash::from_hex(&tx_hash).context("Invalid multisig request hash")?;
        self.pending_multisig.write().cancel(&expected_hash)
    }

    pub async fn inspect_multisig_signing_request(
        &self,
        encoded: String,
    ) -> Result<MultisigSigningRequest> {
        let parsed = parse_multisig_signing_request(&encoded, *self.wallet.get_network())?;
        let (threshold, participants, signer_id) =
            self.resolve_multisig_signing_configuration(&parsed).await?;

        Ok(parsed.into_request(threshold, participants, signer_id))
    }

    pub async fn sign_multisig_signing_request(
        &self,
        encoded: String,
    ) -> Result<MultisigSignatureShare> {
        let parsed = parse_multisig_signing_request(&encoded, *self.wallet.get_network())?;
        let (_, _, signer_id) = self.resolve_multisig_signing_configuration(&parsed).await?;
        let signer_id = signer_id.context(
            "The opened wallet is not an authorized participant for this multisig request",
        )?;
        let signature = self.wallet.sign_data(parsed.hash.as_bytes());

        create_multisig_signature_share(&parsed.hash, signer_id, signature)
    }

    fn store_pending_multisig_transaction(
        &self,
        unsigned: UnsignedTransaction,
        state: TransactionBuilderState,
        transaction_type: TransactionTypeBuilder,
        configuration: MultiSigPayload,
    ) -> Result<MultisigSigningRequest> {
        let hash = unsigned.get_hash_for_multisig();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            *self.wallet.get_network(),
            self.wallet.get_keypair(),
        )?;
        self.pending_multisig.write().insert(
            hash.clone(),
            PendingMultisigTransaction {
                unsigned,
                state,
                transaction_type,
                configuration,
            },
        )?;

        info!("Unsigned multisig transaction created: {}", hash);
        Ok(request)
    }

    async fn resolve_multisig_signing_configuration(
        &self,
        request: &ParsedMultisigSigningRequest,
    ) -> Result<(u8, Vec<ParticipantDartPayload>, Option<u8>)> {
        let source = Address::from_string(&request.source)
            .context("Invalid multisig signing request source")?;
        let network_handler = self
            .wallet
            .get_network_handler()
            .lock()
            .await
            .clone()
            .context("The wallet must be online to verify a multisig signing request")?;
        // The daemon's `get_multisig_at_topoheight` endpoint performs an exact
        // version lookup. A transaction reference is not the configuration's
        // activation topoheight, so use the latest configuration that consensus
        // would apply when the transaction is submitted.
        let result: GetMultisigResult = network_handler
            .get_api()
            .client()
            .call_with(
                "get_multisig",
                &GetMultisigParams {
                    address: Cow::Borrowed(&source),
                },
            )
            .await
            .context("Unable to verify the multisig configuration with the node")?;
        let MultisigState::Active {
            participants,
            threshold,
        } = result.state
        else {
            bail!("The multisig configuration was not active for this request");
        };
        validate_multisig_setup(threshold, participants.len())?;

        let mut signer_id = None;
        let participants = participants
            .into_iter()
            .enumerate()
            .map(|(id, participant)| {
                if participant.get_public_key() == self.wallet.get_public_key() {
                    signer_id = Some(id as u8);
                }
                ParticipantDartPayload {
                    id: id as u8,
                    address: participant.to_string(),
                }
            })
            .collect();

        Ok((threshold, participants, signer_id))
    }

    async fn build_unsigned_transaction(
        &self,
        tx_type: TransactionTypeBuilder,
        fee: FeeBuilder,
        threshold: u8,
    ) -> Result<(UnsignedTransaction, TransactionBuilderState)> {
        let storage = self.wallet.get_storage().write().await;
        let mut state = self
            .wallet
            .create_transaction_state_with_storage(
                &storage,
                &tx_type,
                fee,
                BaseFeeMode::None,
                None,
                None,
            )
            .await
            .context("Error while creating transaction state")?;

        let unsigned = self
            .wallet
            .create_unsigned_transaction(
                &mut state,
                Some(threshold),
                tx_type,
                fee,
                storage.get_tx_version().await?,
            )
            .context("Error while building unsigned transaction")?;
        info!(
            "Unsigned transaction created: {}",
            unsigned.get_hash_for_multisig()
        );
        Ok((unsigned, state))
    }
}

#[cfg(test)]
mod tests;
