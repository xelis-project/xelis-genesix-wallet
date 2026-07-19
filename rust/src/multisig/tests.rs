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
    multisig_request_signing_bytes, parse_multisig_signature_share, parse_multisig_signing_request,
    validate_multisig_setup, MultisigSignatureShareEnvelope, MultisigSigningRequestEnvelope,
    MultisigSigningRequestTransaction, PendingMultisigStore, MAX_MULTISIG_SIGNATURE_SHARE_SIZE,
    MAX_MULTISIG_SIGNING_REQUEST_SIZE,
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
    let MultisigSigningRequestTransaction::Burn { amount, .. } = &mut envelope.payload.transaction
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
    let MultisigSigningRequestTransaction::Burn { amount, .. } = &mut envelope.payload.transaction
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
    let share = create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();

    let error = parse_multisig_signature_share(&share.encoded, &Hash::new([8; 32])).unwrap_err();

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
    let share = create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();
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
    let share = create_multisig_signature_share(&hash, 3, signer.sign(hash.as_bytes())).unwrap();
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
