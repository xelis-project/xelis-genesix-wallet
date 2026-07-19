use anyhow::{bail, ensure, Context, Result};
use serde::{Deserialize, Serialize};
use xelis_common::{
    config::MAX_TRANSACTION_SIZE,
    crypto::{elgamal::PublicKey, proofs::BalanceProof, Hash, KeyPair, Signature},
    network::Network,
    serializer::Serializer,
    transaction::{
        builder::{TransactionTypeBuilder, UnsignedTransaction},
        multisig::{MultiSig, SignatureId},
        MultiSigPayload, Role, TransactionType, MAX_MULTISIG_PARTICIPANTS,
    },
};

use crate::api::models::wallet_dtos::{
    MultisigSignatureShare, MultisigSigningRequest, MultisigSigningTransaction,
    MultisigSigningTransfer, ParticipantDartPayload, SignatureMultisig,
};

const MULTISIG_SIGNING_REQUEST_VERSION: u8 = 1;
const MULTISIG_SIGNATURE_SHARE_VERSION: u8 = 1;
const MULTISIG_SIGNING_REQUEST_DOMAIN: &[u8] = b"genesix:multisig-signing-request:v1\0";
const MAX_MULTISIG_SIGNING_REQUEST_SIZE: usize = MAX_TRANSACTION_SIZE * 3;
const MAX_MULTISIG_SIGNATURE_SHARE_SIZE: usize = 1024;

#[derive(Serialize, Deserialize, Clone)]
struct MultisigSigningRequestPayload {
    version: u8,
    network: Network,
    unsigned_transaction: String,
    transaction: MultisigSigningRequestTransaction,
}

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case", tag = "type", content = "details")]
enum MultisigSigningRequestTransaction {
    Transfers {
        transfers: Vec<MultisigSigningRequestTransfer>,
    },
    Burn {
        asset: String,
        amount: u64,
    },
    DeleteMultisig,
}

#[derive(Serialize, Deserialize, Clone)]
struct MultisigSigningRequestTransfer {
    amount: u64,
    asset: String,
    destination: String,
    has_extra_data: bool,
    amount_proof: String,
}

#[derive(Serialize, Deserialize)]
struct MultisigSigningRequestEnvelope {
    payload: MultisigSigningRequestPayload,
    source_signature: String,
}

#[derive(Serialize, Deserialize)]
struct MultisigSignatureShareEnvelope {
    version: u8,
    request_hash: String,
    signer_id: u8,
    signature: String,
}

#[derive(Debug)]
pub(super) struct ParsedMultisigSigningRequest {
    encoded: String,
    pub hash: Hash,
    pub source: String,
    pub network: Network,
    pub fee: u64,
    pub fee_limit: u64,
    pub nonce: u64,
    pub reference_topoheight: u64,
    transaction: MultisigSigningTransaction,
}

impl ParsedMultisigSigningRequest {
    pub fn into_request(
        self,
        threshold: u8,
        participants: Vec<ParticipantDartPayload>,
        signer_id: Option<u8>,
    ) -> MultisigSigningRequest {
        MultisigSigningRequest {
            encoded: self.encoded,
            hash: self.hash.to_hex(),
            source: self.source,
            network: self.network.to_string().to_lowercase(),
            fee: self.fee,
            fee_limit: self.fee_limit,
            nonce: self.nonce,
            reference_topoheight: self.reference_topoheight,
            threshold,
            participants,
            signer_id,
            transaction: self.transaction,
        }
    }
}

pub(super) struct PendingMultisigStore<T> {
    request: Option<(Hash, T)>,
}

impl<T> Default for PendingMultisigStore<T> {
    fn default() -> Self {
        Self { request: None }
    }
}

impl<T> PendingMultisigStore<T> {
    pub fn insert(&mut self, hash: Hash, payload: T) -> Result<()> {
        if self.request.is_some() {
            bail!("Another multisig request is already pending");
        }

        self.request = Some((hash, payload));
        Ok(())
    }

    pub fn hash(&self) -> Option<&Hash> {
        self.request.as_ref().map(|(hash, _)| hash)
    }

    pub fn cancel(&mut self, expected_hash: &Hash) -> Result<()> {
        self.ensure_expected_hash(expected_hash)?;
        self.request = None;
        Ok(())
    }

    pub fn take_validated<R>(
        &mut self,
        expected_hash: &Hash,
        validate: impl FnOnce(&T) -> Result<R>,
    ) -> Result<(T, R)> {
        self.ensure_expected_hash(expected_hash)?;

        let validation = {
            let (_, payload) = self
                .request
                .as_ref()
                .context("No multisig request is pending")?;
            validate(payload)?
        };

        let (_, payload) = self
            .request
            .take()
            .context("No multisig request is pending")?;
        Ok((payload, validation))
    }

    fn ensure_expected_hash(&self, expected_hash: &Hash) -> Result<()> {
        let (actual_hash, _) = self
            .request
            .as_ref()
            .context("No multisig request is pending")?;

        if actual_hash != expected_hash {
            bail!("The multisig request does not match the pending transaction");
        }

        Ok(())
    }
}

pub(super) fn validate_multisig_setup(threshold: u8, participants: usize) -> Result<()> {
    if participants == 0 {
        bail!("At least one multisig participant is required");
    }
    if participants > MAX_MULTISIG_PARTICIPANTS {
        bail!("Too many multisig participants");
    }
    if threshold == 0 || threshold as usize > participants {
        bail!("Invalid multisig threshold");
    }

    Ok(())
}

pub(super) fn build_verified_multisig(
    expected_hash: &Hash,
    configuration: &MultiSigPayload,
    signatures: &[SignatureMultisig],
) -> Result<MultiSig> {
    if signatures.len() != configuration.threshold as usize {
        bail!("The multisig signature count does not match the configured threshold");
    }

    let mut multisig = MultiSig::new();
    for signature in signatures {
        let participant = configuration
            .participants
            .get_index(signature.id as usize)
            .context("The multisig participant id is invalid")?;
        let participant = participant
            .decompress()
            .context("The multisig participant key is invalid")?;
        let parsed_signature = Signature::from_hex(&signature.signature)
            .context("The multisig signature encoding is invalid")?;
        ensure!(
            parsed_signature.to_hex() == signature.signature,
            "The multisig signature encoding is not canonical"
        );

        if !parsed_signature.verify(expected_hash.as_bytes(), &participant) {
            bail!("The multisig signature is invalid for this transaction");
        }

        if !multisig.add_signature(SignatureId {
            id: signature.id,
            signature: parsed_signature,
        }) {
            bail!("A multisig participant was provided more than once");
        }
    }

    Ok(multisig)
}

pub(super) fn create_multisig_signing_request(
    unsigned: &UnsignedTransaction,
    transaction_type: &TransactionTypeBuilder,
    configuration: &MultiSigPayload,
    network: Network,
    source_keypair: &KeyPair,
) -> Result<MultisigSigningRequest> {
    let finalized = unsigned.clone().finalize(source_keypair);
    let transaction = build_signing_request_transaction(
        transaction_type,
        finalized.get_data(),
        network,
        source_keypair,
    )?;
    let payload = MultisigSigningRequestPayload {
        version: MULTISIG_SIGNING_REQUEST_VERSION,
        network,
        unsigned_transaction: unsigned.to_hex(),
        transaction,
    };
    let source_signature = source_keypair.sign(&multisig_request_signing_bytes(&payload)?);
    let envelope = MultisigSigningRequestEnvelope {
        payload,
        source_signature: source_signature.to_hex(),
    };
    let encoded = serde_json::to_string(&envelope)
        .context("Unable to encode the multisig signing request")?;
    let parsed = parse_multisig_signing_request(&encoded, network)?;
    let participants = configuration
        .participants
        .iter()
        .enumerate()
        .map(|(id, participant)| ParticipantDartPayload {
            id: id as u8,
            address: participant
                .clone()
                .to_address(network.is_mainnet())
                .to_string(),
        })
        .collect();

    Ok(parsed.into_request(configuration.threshold, participants, None))
}

pub(super) fn parse_multisig_signing_request(
    encoded: &str,
    expected_network: Network,
) -> Result<ParsedMultisigSigningRequest> {
    ensure!(
        encoded.len() <= MAX_MULTISIG_SIGNING_REQUEST_SIZE,
        "The multisig signing request is too large"
    );
    let envelope: MultisigSigningRequestEnvelope =
        serde_json::from_str(encoded.trim()).context("Invalid multisig signing request")?;
    ensure!(
        envelope.payload.version == MULTISIG_SIGNING_REQUEST_VERSION,
        "Unsupported multisig signing request version"
    );
    ensure!(
        envelope.payload.network == expected_network,
        "The multisig signing request belongs to another network"
    );

    let unsigned = UnsignedTransaction::from_hex(&envelope.payload.unsigned_transaction)
        .context("Invalid unsigned transaction in multisig signing request")?;
    ensure!(
        unsigned.size() <= MAX_TRANSACTION_SIZE,
        "The unsigned transaction is too large"
    );
    ensure!(
        unsigned.to_hex() == envelope.payload.unsigned_transaction,
        "The unsigned transaction encoding is not canonical"
    );
    ensure!(
        unsigned.multisig().is_none(),
        "The multisig signing request already contains signatures"
    );

    let source_signature = Signature::from_hex(&envelope.source_signature)
        .context("Invalid multisig signing request attestation")?;
    ensure!(
        source_signature.to_hex() == envelope.source_signature,
        "The multisig signing request attestation encoding is not canonical"
    );
    let source = unsigned
        .source()
        .decompress()
        .context("Invalid multisig signing request source")?;
    ensure!(
        source_signature.verify(&multisig_request_signing_bytes(&envelope.payload)?, &source,),
        "The multisig signing request attestation is invalid"
    );
    let canonical_encoded = serde_json::to_string(&envelope)
        .context("Unable to normalize the multisig signing request")?;
    ensure!(
        canonical_encoded == encoded.trim(),
        "The multisig signing request encoding is not canonical"
    );

    // UnsignedTransaction currently exposes only its source and multisig fields.
    // Finalizing a clone with an ephemeral key gives us the stable, typed public
    // Transaction getters without changing the canonical unsigned bytes or hash.
    let transaction = unsigned.clone().finalize(&KeyPair::new());
    let transaction_preview = validate_and_build_transaction_preview(
        &envelope.payload.transaction,
        transaction.get_data(),
        expected_network,
        &source,
    )?;
    Ok(ParsedMultisigSigningRequest {
        encoded: canonical_encoded,
        hash: unsigned.get_hash_for_multisig(),
        source: transaction
            .get_source()
            .clone()
            .to_address(expected_network.is_mainnet())
            .to_string(),
        network: expected_network,
        fee: transaction.get_fee(),
        fee_limit: transaction.get_fee_limit(),
        nonce: transaction.get_nonce(),
        reference_topoheight: transaction.get_reference().topoheight,
        transaction: transaction_preview,
    })
}

pub(super) fn create_multisig_signature_share(
    request_hash: &Hash,
    signer_id: u8,
    signature: Signature,
) -> Result<MultisigSignatureShare> {
    let envelope = MultisigSignatureShareEnvelope {
        version: MULTISIG_SIGNATURE_SHARE_VERSION,
        request_hash: request_hash.to_hex(),
        signer_id,
        signature: signature.to_hex(),
    };
    let encoded = serde_json::to_string(&envelope)
        .context("Unable to encode the multisig signature share")?;

    Ok(MultisigSignatureShare {
        encoded,
        request_hash: envelope.request_hash,
        signer_id,
        signature: envelope.signature,
    })
}

pub(super) fn parse_multisig_signature_share(
    encoded: &str,
    expected_hash: &Hash,
) -> Result<SignatureMultisig> {
    ensure!(
        encoded.len() <= MAX_MULTISIG_SIGNATURE_SHARE_SIZE,
        "The multisig signature share is too large"
    );
    let envelope: MultisigSignatureShareEnvelope =
        serde_json::from_str(encoded.trim()).context("Invalid multisig signature share")?;
    ensure!(
        envelope.version == MULTISIG_SIGNATURE_SHARE_VERSION,
        "Unsupported multisig signature share version"
    );
    ensure!(
        envelope.request_hash == expected_hash.to_hex(),
        "The signature share belongs to another multisig request"
    );
    ensure!(
        serde_json::to_string(&envelope)
            .context("Unable to normalize the multisig signature share")?
            == encoded.trim(),
        "The multisig signature share encoding is not canonical"
    );

    let signature =
        Signature::from_hex(&envelope.signature).context("Invalid signature share encoding")?;
    ensure!(
        signature.to_hex() == envelope.signature,
        "The signature share encoding is not canonical"
    );
    Ok(SignatureMultisig {
        id: envelope.signer_id,
        signature: envelope.signature,
    })
}

fn multisig_request_signing_bytes(payload: &MultisigSigningRequestPayload) -> Result<Vec<u8>> {
    let payload = serde_json::to_vec(payload)
        .context("Unable to encode the multisig signing request payload")?;
    let mut bytes = Vec::with_capacity(MULTISIG_SIGNING_REQUEST_DOMAIN.len() + payload.len());
    bytes.extend_from_slice(MULTISIG_SIGNING_REQUEST_DOMAIN);
    bytes.extend_from_slice(&payload);
    Ok(bytes)
}

fn build_signing_request_transaction(
    declared: &TransactionTypeBuilder,
    actual: &TransactionType,
    network: Network,
    source_keypair: &KeyPair,
) -> Result<MultisigSigningRequestTransaction> {
    match (declared, actual) {
        (TransactionTypeBuilder::Transfers(declared), TransactionType::Transfers(actual)) => {
            ensure!(
                declared.len() == actual.len(),
                "The transfer count does not match the unsigned transaction"
            );

            let mut transfers = Vec::with_capacity(declared.len());
            for (declared, actual) in declared.iter().zip(actual) {
                validate_transfer_public_details(declared, actual, network)?;
                let sender_ciphertext = actual
                    .get_ciphertext(Role::Sender)
                    .decompress()
                    .context("The transfer sender ciphertext is invalid")?;
                let amount_proof =
                    BalanceProof::new(source_keypair, declared.amount, sender_ciphertext);

                transfers.push(MultisigSigningRequestTransfer {
                    amount: declared.amount,
                    asset: actual.get_asset().to_hex(),
                    destination: actual
                        .get_destination()
                        .clone()
                        .to_address(network.is_mainnet())
                        .to_string(),
                    has_extra_data: actual.get_extra_data().is_some(),
                    amount_proof: amount_proof.to_hex(),
                });
            }

            Ok(MultisigSigningRequestTransaction::Transfers { transfers })
        }
        (TransactionTypeBuilder::Burn(declared), TransactionType::Burn(actual)) => {
            ensure!(
                declared.asset == actual.asset && declared.amount == actual.amount,
                "The burn details do not match the unsigned transaction"
            );
            Ok(MultisigSigningRequestTransaction::Burn {
                asset: actual.asset.to_hex(),
                amount: actual.amount,
            })
        }
        (TransactionTypeBuilder::MultiSig(declared), TransactionType::MultiSig(actual)) => {
            ensure!(
                declared.threshold == actual.threshold,
                "The multisig threshold does not match the unsigned transaction"
            );
            ensure!(
                declared.participants.len() == actual.participants.len()
                    && declared
                        .participants
                        .iter()
                        .zip(&actual.participants)
                        .all(|(declared, actual)| declared.get_public_key() == actual),
                "The multisig participants do not match the unsigned transaction"
            );
            ensure!(
                actual.is_delete(),
                "Only multisig deletion requests are supported"
            );
            Ok(MultisigSigningRequestTransaction::DeleteMultisig)
        }
        _ => bail!("The declared transaction type does not match the unsigned transaction"),
    }
}

fn validate_and_build_transaction_preview(
    declared: &MultisigSigningRequestTransaction,
    actual: &TransactionType,
    network: Network,
    source: &PublicKey,
) -> Result<MultisigSigningTransaction> {
    match (declared, actual) {
        (
            MultisigSigningRequestTransaction::Transfers {
                transfers: declared,
            },
            TransactionType::Transfers(actual),
        ) => {
            ensure!(
                declared.len() == actual.len(),
                "The transfer count does not match the unsigned transaction"
            );

            let mut transfers = Vec::with_capacity(declared.len());
            for (declared, actual) in declared.iter().zip(actual) {
                ensure!(
                    declared.destination
                        == actual
                            .get_destination()
                            .clone()
                            .to_address(network.is_mainnet())
                            .to_string(),
                    "A transfer destination does not match the unsigned transaction"
                );
                ensure!(
                    declared.asset == actual.get_asset().to_hex(),
                    "A transfer asset does not match the unsigned transaction"
                );
                ensure!(
                    declared.has_extra_data == actual.get_extra_data().is_some(),
                    "Transfer extra data does not match the unsigned transaction"
                );
                let amount_proof = BalanceProof::from_hex(&declared.amount_proof)
                    .context("The transfer amount proof is invalid")?;
                ensure!(
                    amount_proof.to_hex() == declared.amount_proof,
                    "The transfer amount proof encoding is not canonical"
                );
                ensure!(
                    amount_proof.amount() == declared.amount,
                    "The transfer amount does not match its proof"
                );
                let sender_ciphertext = actual
                    .get_ciphertext(Role::Sender)
                    .decompress()
                    .context("The transfer sender ciphertext is invalid")?;
                amount_proof
                    .verify(source, sender_ciphertext)
                    .context("The transfer amount proof does not match the unsigned transaction")?;

                transfers.push(MultisigSigningTransfer {
                    amount: declared.amount,
                    asset: declared.asset.clone(),
                    destination: declared.destination.clone(),
                    has_extra_data: declared.has_extra_data,
                });
            }

            Ok(MultisigSigningTransaction::Transfers { transfers })
        }
        (
            MultisigSigningRequestTransaction::Burn { asset, amount },
            TransactionType::Burn(actual),
        ) => {
            ensure!(
                asset == &actual.asset.to_hex() && amount == &actual.amount,
                "The burn details do not match the unsigned transaction"
            );
            Ok(MultisigSigningTransaction::Burn {
                asset: actual.asset.to_hex(),
                amount: actual.amount,
            })
        }
        (MultisigSigningRequestTransaction::DeleteMultisig, TransactionType::MultiSig(actual)) => {
            ensure!(
                actual.is_delete(),
                "Only multisig deletion requests are supported"
            );
            Ok(MultisigSigningTransaction::DeleteMultisig)
        }
        _ => bail!("The declared transaction type does not match the unsigned transaction"),
    }
}

fn validate_transfer_public_details(
    declared: &xelis_common::transaction::builder::TransferBuilder,
    actual: &xelis_common::transaction::TransferPayload,
    network: Network,
) -> Result<()> {
    ensure!(
        declared.destination.is_mainnet() == network.is_mainnet(),
        "A transfer destination belongs to another network"
    );
    ensure!(
        declared.destination.get_public_key() == actual.get_destination(),
        "A transfer destination does not match the unsigned transaction"
    );
    ensure!(
        &declared.asset == actual.get_asset(),
        "A transfer asset does not match the unsigned transaction"
    );
    let declared_has_extra_data =
        declared.extra_data.is_some() || declared.destination.get_extra_data().is_some();
    ensure!(
        declared_has_extra_data == actual.get_extra_data().is_some(),
        "Transfer extra data does not match the unsigned transaction"
    );

    Ok(())
}

#[cfg(test)]
mod tests {
    use indexmap::IndexSet;
    use xelis_common::{
        config::{COIN_VALUE, XELIS_ASSET},
        crypto::{proofs::BalanceProof, Hash, KeyPair},
        network::Network,
        serializer::Serializer,
        transaction::{
            builder::{FeeBuilder, TransactionBuilder, TransactionTypeBuilder, TransferBuilder},
            mock::{TrackedAccount, TrackedAccountState},
            BurnPayload, MultiSigPayload, Reference, TxVersion,
        },
    };

    use super::{
        build_verified_multisig, create_multisig_signature_share, create_multisig_signing_request,
        multisig_request_signing_bytes, parse_multisig_signature_share,
        parse_multisig_signing_request, validate_multisig_setup, MultisigSignatureShareEnvelope,
        MultisigSigningRequestEnvelope, MultisigSigningRequestTransaction, PendingMultisigStore,
        MAX_MULTISIG_SIGNATURE_SHARE_SIZE, MAX_MULTISIG_SIGNING_REQUEST_SIZE,
    };
    use crate::api::models::wallet_dtos::{MultisigSigningTransaction, SignatureMultisig};

    fn signature(id: u8, keypair: &KeyPair, hash: &Hash) -> SignatureMultisig {
        SignatureMultisig {
            id,
            signature: keypair.sign(hash.as_bytes()).to_hex(),
        }
    }

    fn configuration(keypairs: &[&KeyPair], threshold: u8) -> MultiSigPayload {
        MultiSigPayload {
            threshold,
            participants: keypairs
                .iter()
                .map(|keypair| keypair.get_public_key().compress())
                .collect::<IndexSet<_>>(),
        }
    }

    fn burn_request_fixture() -> (
        TrackedAccount,
        xelis_common::transaction::builder::UnsignedTransaction,
        TransactionTypeBuilder,
        MultiSigPayload,
    ) {
        let mut source = TrackedAccount::new();
        source.set_balance(XELIS_ASSET, 100 * COIN_VALUE);
        let mut state = TrackedAccountState {
            balances: source.balances.clone(),
            reference: Reference {
                hash: Hash::zero(),
                topoheight: 42,
            },
            nonce: source.nonce,
        };
        let transaction_type = TransactionTypeBuilder::Burn(BurnPayload {
            asset: XELIS_ASSET,
            amount: 10 * COIN_VALUE,
        });
        let builder = TransactionBuilder::new(
            TxVersion::V1,
            source.get_public_key(),
            Some(1),
            transaction_type.clone(),
            FeeBuilder::default(),
        );
        let unsigned = builder.build_unsigned(&mut state, &source.keypair).unwrap();
        let signer = KeyPair::new();
        let configuration = configuration(&[&signer], 1);

        (source, unsigned, transaction_type, configuration)
    }

    fn transfer_request_fixture() -> (
        TrackedAccount,
        xelis_common::transaction::builder::UnsignedTransaction,
        TransactionTypeBuilder,
        MultiSigPayload,
    ) {
        let mut source = TrackedAccount::new();
        source.set_balance(XELIS_ASSET, 100 * COIN_VALUE);
        let first_destination = TrackedAccount::new();
        let second_destination = TrackedAccount::new();
        let mut state = TrackedAccountState {
            balances: source.balances.clone(),
            reference: Reference {
                hash: Hash::zero(),
                topoheight: 42,
            },
            nonce: source.nonce,
        };
        let transaction_type = TransactionTypeBuilder::Transfers(vec![
            TransferBuilder {
                asset: XELIS_ASSET,
                amount: 10 * COIN_VALUE,
                destination: first_destination.address(),
                extra_data: None,
                encrypt_extra_data: true,
            },
            TransferBuilder {
                asset: XELIS_ASSET,
                amount: 20 * COIN_VALUE,
                destination: second_destination.address(),
                extra_data: None,
                encrypt_extra_data: true,
            },
        ]);
        let builder = TransactionBuilder::new(
            TxVersion::V1,
            source.get_public_key(),
            Some(1),
            transaction_type.clone(),
            FeeBuilder::default(),
        );
        let unsigned = builder.build_unsigned(&mut state, &source.keypair).unwrap();
        let signer = KeyPair::new();
        let configuration = configuration(&[&signer], 1);

        (source, unsigned, transaction_type, configuration)
    }

    #[test]
    fn pending_store_rejects_overwrite() {
        let mut store = PendingMultisigStore::default();
        store.insert(Hash::new([1; 32]), "first").unwrap();

        let error = store.insert(Hash::new([2; 32]), "second").unwrap_err();

        assert_eq!(
            error.to_string(),
            "Another multisig request is already pending"
        );
        assert_eq!(store.hash(), Some(&Hash::new([1; 32])));
    }

    #[test]
    fn pending_store_keeps_request_after_hash_mismatch() {
        let mut store = PendingMultisigStore::default();
        let pending_hash = Hash::new([1; 32]);
        store.insert(pending_hash.clone(), "request").unwrap();

        let error = store
            .take_validated(&Hash::new([2; 32]), |_| Ok(()))
            .unwrap_err();

        assert_eq!(
            error.to_string(),
            "The multisig request does not match the pending transaction"
        );
        assert_eq!(store.hash(), Some(&pending_hash));
    }

    #[test]
    fn pending_store_keeps_request_after_validation_failure() {
        let mut store = PendingMultisigStore::default();
        let pending_hash = Hash::new([1; 32]);
        store.insert(pending_hash.clone(), "request").unwrap();

        let error = store
            .take_validated::<()>(&pending_hash, |_| anyhow::bail!("invalid request"))
            .unwrap_err();

        assert_eq!(error.to_string(), "invalid request");
        assert_eq!(store.hash(), Some(&pending_hash));
    }

    #[test]
    fn pending_store_cancels_only_matching_request() {
        let mut store = PendingMultisigStore::default();
        let pending_hash = Hash::new([1; 32]);
        store.insert(pending_hash.clone(), "request").unwrap();

        assert!(store.cancel(&Hash::new([2; 32])).is_err());
        assert_eq!(store.hash(), Some(&pending_hash));

        store.cancel(&pending_hash).unwrap();
        assert_eq!(store.hash(), None);
    }

    #[test]
    fn multisig_setup_rejects_invalid_threshold_and_participant_count() {
        assert!(validate_multisig_setup(0, 1).is_err());
        assert!(validate_multisig_setup(2, 1).is_err());
        assert!(validate_multisig_setup(1, 0).is_err());
        assert!(validate_multisig_setup(1, 256).is_err());
        assert!(validate_multisig_setup(2, 3).is_ok());
    }

    #[test]
    fn verified_multisig_accepts_exact_valid_threshold() {
        let first = KeyPair::new();
        let second = KeyPair::new();
        let hash = Hash::new([7; 32]);
        let configuration = configuration(&[&first, &second], 2);
        let signatures = vec![signature(0, &first, &hash), signature(1, &second, &hash)];

        let multisig = build_verified_multisig(&hash, &configuration, &signatures).unwrap();

        assert_eq!(multisig.len(), 2);
    }

    #[test]
    fn verified_multisig_rejects_wrong_hash_without_consuming_store() {
        let signer = KeyPair::new();
        let pending_hash = Hash::new([7; 32]);
        let signed_hash = Hash::new([8; 32]);
        let configuration = configuration(&[&signer], 1);
        let signatures = vec![signature(0, &signer, &signed_hash)];
        let mut store = PendingMultisigStore::default();
        store.insert(pending_hash.clone(), configuration).unwrap();

        let result = store.take_validated(&pending_hash, |configuration| {
            build_verified_multisig(&pending_hash, configuration, &signatures)
        });

        assert!(result.is_err());
        assert_eq!(store.hash(), Some(&pending_hash));
    }

    #[test]
    fn verified_multisig_rejects_duplicate_participant() {
        let first = KeyPair::new();
        let second = KeyPair::new();
        let hash = Hash::new([7; 32]);
        let configuration = configuration(&[&first, &second], 2);
        let signatures = vec![signature(0, &first, &hash), signature(0, &first, &hash)];

        assert!(build_verified_multisig(&hash, &configuration, &signatures).is_err());
    }

    #[test]
    fn verified_multisig_rejects_wrong_participant_key() {
        let expected = KeyPair::new();
        let wrong = KeyPair::new();
        let hash = Hash::new([7; 32]);
        let configuration = configuration(&[&expected], 1);
        let signatures = vec![signature(0, &wrong, &hash)];

        assert!(build_verified_multisig(&hash, &configuration, &signatures).is_err());
    }

    #[test]
    fn verified_multisig_rejects_invalid_participant_id() {
        let signer = KeyPair::new();
        let hash = Hash::new([7; 32]);
        let configuration = configuration(&[&signer], 1);
        let signatures = vec![signature(1, &signer, &hash)];

        assert!(build_verified_multisig(&hash, &configuration, &signatures).is_err());
    }

    #[test]
    fn signing_request_round_trip_recomputes_hash_and_verified_burn_preview() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();

        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let parsed = parse_multisig_signing_request(&request.encoded, Network::Testnet).unwrap();

        assert_eq!(request.hash, unsigned.get_hash_for_multisig().to_hex());
        assert_eq!(parsed.hash, unsigned.get_hash_for_multisig());
        assert_eq!(parsed.reference_topoheight, 42);
        assert!(matches!(
            request.transaction,
            MultisigSigningTransaction::Burn {
                asset,
                amount
            } if asset == XELIS_ASSET.to_hex() && amount == 10 * COIN_VALUE
        ));
    }

    #[test]
    fn signing_request_round_trip_verifies_confidential_transfer_amounts() {
        let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();

        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let parsed = parse_multisig_signing_request(&request.encoded, Network::Testnet).unwrap();

        assert_eq!(parsed.hash, unsigned.get_hash_for_multisig());
        assert!(matches!(
            request.transaction,
            MultisigSigningTransaction::Transfers { transfers }
                if transfers.len() == 2
                    && transfers[0].amount == 10 * COIN_VALUE
                    && transfers[1].amount == 20 * COIN_VALUE
        ));
    }

    #[test]
    fn signing_request_rejects_transfer_amount_changed_after_proof() {
        let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        let MultisigSigningRequestTransaction::Transfers { transfers } =
            &mut envelope.payload.transaction
        else {
            panic!("expected transfer request");
        };
        transfers[0].amount += 1;
        envelope.source_signature = source
            .keypair
            .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
            .to_hex();
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
        assert_eq!(
            error.to_string(),
            "The transfer amount does not match its proof"
        );
    }

    #[test]
    fn signing_request_rejects_reordered_transfer_amount_proofs() {
        let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        let MultisigSigningRequestTransaction::Transfers { transfers } =
            &mut envelope.payload.transaction
        else {
            panic!("expected transfer request");
        };
        let first_proof = transfers[0].amount_proof.clone();
        transfers[0].amount_proof = transfers[1].amount_proof.clone();
        transfers[1].amount_proof = first_proof;
        envelope.source_signature = source
            .keypair
            .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
            .to_hex();
        let encoded = serde_json::to_string(&envelope).unwrap();

        assert!(parse_multisig_signing_request(&encoded, Network::Testnet).is_err());
    }

    #[test]
    fn signing_request_rejects_proof_for_another_ciphertext() {
        let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        let MultisigSigningRequestTransaction::Transfers { transfers } =
            &mut envelope.payload.transaction
        else {
            panic!("expected transfer request");
        };
        let amount = transfers[0].amount;
        let unrelated_ciphertext = source.keypair.get_public_key().encrypt(amount);
        transfers[0].amount_proof =
            BalanceProof::new(&source.keypair, amount, unrelated_ciphertext).to_hex();
        envelope.source_signature = source
            .keypair
            .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
            .to_hex();
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
        assert!(error
            .to_string()
            .contains("does not match the unsigned transaction"));
    }

    #[test]
    fn signing_request_rejects_non_canonical_amount_proof() {
        let (source, unsigned, transaction_type, configuration) = transfer_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        let MultisigSigningRequestTransaction::Transfers { transfers } =
            &mut envelope.payload.transaction
        else {
            panic!("expected transfer request");
        };
        transfers[0].amount_proof.push_str("00");
        envelope.source_signature = source
            .keypair
            .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
            .to_hex();
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
        assert_eq!(
            error.to_string(),
            "The transfer amount proof encoding is not canonical"
        );
    }

    #[test]
    fn signing_request_rejects_wrong_network() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();

        let error = parse_multisig_signing_request(&request.encoded, Network::Mainnet).unwrap_err();

        assert_eq!(
            error.to_string(),
            "The multisig signing request belongs to another network"
        );
    }

    #[test]
    fn signing_request_rejects_oversized_input_before_parsing() {
        let encoded = "x".repeat(MAX_MULTISIG_SIGNING_REQUEST_SIZE + 1);

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();

        assert_eq!(
            error.to_string(),
            "The multisig signing request is too large"
        );
    }

    #[test]
    fn signing_request_rejects_non_canonical_unsigned_bytes() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        envelope.payload.unsigned_transaction.push_str("00");
        envelope.source_signature = source
            .keypair
            .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
            .to_hex();
        let encoded = serde_json::to_string(&envelope).unwrap();

        assert!(parse_multisig_signing_request(&encoded, Network::Testnet).is_err());
    }

    #[test]
    fn signing_request_rejects_source_attested_public_detail_mismatch() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        let MultisigSigningRequestTransaction::Burn { amount, .. } =
            &mut envelope.payload.transaction
        else {
            panic!("expected burn request");
        };
        *amount += 1;
        envelope.source_signature = source
            .keypair
            .sign(&multisig_request_signing_bytes(&envelope.payload).unwrap())
            .to_hex();
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
        assert_eq!(
            error.to_string(),
            "The burn details do not match the unsigned transaction"
        );
    }

    #[test]
    fn signing_request_rejects_tampered_attestation() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        let MultisigSigningRequestTransaction::Burn { amount, .. } =
            &mut envelope.payload.transaction
        else {
            panic!("expected burn request");
        };
        *amount += 1;
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
        assert_eq!(
            error.to_string(),
            "The multisig signing request attestation is invalid"
        );
    }

    #[test]
    fn signing_request_rejects_non_canonical_attestation_encoding() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let mut envelope: MultisigSigningRequestEnvelope =
            serde_json::from_str(&request.encoded).unwrap();
        envelope.source_signature.push_str("00");
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();
        assert_eq!(
            error.to_string(),
            "The multisig signing request attestation encoding is not canonical"
        );
    }

    #[test]
    fn signing_request_rejects_non_canonical_envelope_encoding() {
        let (source, unsigned, transaction_type, configuration) = burn_request_fixture();
        let request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            Network::Testnet,
            &source.keypair,
        )
        .unwrap();
        let encoded = request.encoded.replace(",\"", ", \"");

        let error = parse_multisig_signing_request(&encoded, Network::Testnet).unwrap_err();

        assert_eq!(
            error.to_string(),
            "The multisig signing request encoding is not canonical"
        );
    }

    #[test]
    fn signature_share_is_bound_to_request_hash_and_signer_id() {
        let signer = KeyPair::new();
        let hash = Hash::new([9; 32]);
        let signature = signer.sign(hash.as_bytes());

        let share = create_multisig_signature_share(&hash, 3, signature).unwrap();
        let parsed = parse_multisig_signature_share(&share.encoded, &hash).unwrap();

        assert_eq!(share.request_hash, hash.to_hex());
        assert_eq!(share.signer_id, 3);
        assert!(share.encoded.contains(&hash.to_hex()));
        assert_eq!(parsed.id, 3);
        assert_eq!(parsed.signature, share.signature);
    }

    #[test]
    fn signature_share_rejects_another_request_hash() {
        let signer = KeyPair::new();
        let hash = Hash::new([9; 32]);
        let share =
            create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();

        let error =
            parse_multisig_signature_share(&share.encoded, &Hash::new([8; 32])).unwrap_err();

        assert_eq!(
            error.to_string(),
            "The signature share belongs to another multisig request"
        );
    }

    #[test]
    fn signature_share_rejects_oversized_input_before_parsing() {
        let encoded = "x".repeat(MAX_MULTISIG_SIGNATURE_SHARE_SIZE + 1);

        let error = parse_multisig_signature_share(&encoded, &Hash::new([9; 32])).unwrap_err();

        assert_eq!(
            error.to_string(),
            "The multisig signature share is too large"
        );
    }

    #[test]
    fn signature_share_rejects_non_canonical_encoding() {
        let signer = KeyPair::new();
        let hash = Hash::new([9; 32]);
        let share =
            create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();
        let encoded = share.encoded.replace(",\"", ", \"");

        let error = parse_multisig_signature_share(&encoded, &hash).unwrap_err();

        assert_eq!(
            error.to_string(),
            "The multisig signature share encoding is not canonical"
        );
    }

    #[test]
    fn signature_share_rejects_non_canonical_signature_encoding() {
        let signer = KeyPair::new();
        let hash = Hash::new([9; 32]);
        let share =
            create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();
        let mut envelope: MultisigSignatureShareEnvelope =
            serde_json::from_str(&share.encoded).unwrap();
        envelope.signature.push_str("00");
        let encoded = serde_json::to_string(&envelope).unwrap();

        let error = parse_multisig_signature_share(&encoded, &hash).unwrap_err();
        assert_eq!(
            error.to_string(),
            "The signature share encoding is not canonical"
        );
    }
}
