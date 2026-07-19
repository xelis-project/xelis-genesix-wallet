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
mod tests;
