use std::{cell::Cell, future::ready};

use futures::executor::block_on;
use xelis_common::{
    api::{daemon::MultisigState, DataElement, DataValue},
    crypto::{Address, AddressType, Hash, KeyPair, Signature},
    serializer::Serializer,
};

use super::{
    create_authorized_multisig_signature_share, is_multisig_participant_address_valid,
    parse_multisig_participants, resolve_active_multisig_configuration,
    resolve_multisig_signing_configuration_with,
};

#[test]
fn multisig_participant_must_be_normal_external_and_on_the_same_network() {
    let wallet = KeyPair::new();
    let wallet_public_key = wallet.get_public_key().compress();
    let participant = KeyPair::new();
    let valid = participant.get_public_key().to_address(false);

    assert!(is_multisig_participant_address_valid(
        &valid,
        false,
        &wallet_public_key
    ));
    assert!(!is_multisig_participant_address_valid(
        &participant.get_public_key().to_address(true),
        false,
        &wallet_public_key
    ));
    assert!(!is_multisig_participant_address_valid(
        &wallet.get_public_key().to_address(false),
        false,
        &wallet_public_key
    ));

    let integrated = Address::new(
        false,
        AddressType::Data(DataElement::Value(DataValue::String("memo".to_owned()))),
        participant.get_public_key().compress(),
    );
    assert!(!is_multisig_participant_address_valid(
        &integrated,
        false,
        &wallet_public_key
    ));
}

#[test]
fn multisig_participants_preserve_order() {
    let wallet = KeyPair::new();
    let wallet_public_key = wallet.get_public_key().compress();
    let first = KeyPair::new().get_public_key().to_address(false);
    let second = KeyPair::new().get_public_key().to_address(false);

    let parsed = parse_multisig_participants(
        vec![first.to_string(), second.to_string()],
        false,
        &wallet_public_key,
    )
    .unwrap();

    assert_eq!(parsed.iter().collect::<Vec<_>>(), vec![&first, &second]);
}

#[test]
fn multisig_participants_reject_duplicates() {
    let wallet = KeyPair::new();
    let wallet_public_key = wallet.get_public_key().compress();
    let participant = KeyPair::new()
        .get_public_key()
        .to_address(false)
        .to_string();

    let error = parse_multisig_participants(
        vec![participant.clone(), participant],
        false,
        &wallet_public_key,
    )
    .unwrap_err();

    assert_eq!(
        error.to_string(),
        "A multisig participant was provided more than once"
    );
}

#[test]
fn multisig_participants_reject_invalid_self_and_wrong_network_addresses() {
    let wallet = KeyPair::new();
    let wallet_public_key = wallet.get_public_key().compress();
    let cases = [
        "invalid-address".to_owned(),
        wallet.get_public_key().to_address(false).to_string(),
        KeyPair::new().get_public_key().to_address(true).to_string(),
    ];

    for participant in cases {
        let error =
            parse_multisig_participants(vec![participant], false, &wallet_public_key).unwrap_err();

        assert_eq!(error.to_string(), "Invalid multisig participant address");
    }
}

#[test]
fn active_configuration_preserves_participant_ids_and_detects_opened_wallet() {
    let first = KeyPair::new();
    let opened_wallet = KeyPair::new();
    let third = KeyPair::new();
    let participants = vec![
        first.get_public_key().to_address(false),
        opened_wallet.get_public_key().to_address(false),
        third.get_public_key().to_address(false),
    ];

    let resolved = resolve_active_multisig_configuration(
        MultisigState::Active {
            participants: participants.clone(),
            threshold: 2,
        },
        &opened_wallet.get_public_key().compress(),
    )
    .unwrap();

    assert_eq!(resolved.threshold, 2);
    assert_eq!(resolved.signer_id, Some(1));
    assert_eq!(resolved.participants.len(), participants.len());
    for (id, (actual, expected)) in resolved
        .participants
        .iter()
        .zip(participants.iter())
        .enumerate()
    {
        assert_eq!(actual.id, id as u8);
        assert_eq!(actual.address, expected.to_string());
    }
}

#[test]
fn active_configuration_does_not_assign_signer_id_to_non_participant() {
    let opened_wallet = KeyPair::new();
    let participant = KeyPair::new();

    let resolved = resolve_active_multisig_configuration(
        MultisigState::Active {
            participants: vec![participant.get_public_key().to_address(false)],
            threshold: 1,
        },
        &opened_wallet.get_public_key().compress(),
    )
    .unwrap();

    assert_eq!(resolved.signer_id, None);
}

#[test]
fn active_configuration_rejects_deleted_state() {
    let opened_wallet = KeyPair::new();
    let wallet_public_key = opened_wallet.get_public_key().compress();

    let error = resolve_active_multisig_configuration(MultisigState::Deleted, &wallet_public_key)
        .unwrap_err();
    assert_eq!(
        error.to_string(),
        "The multisig configuration was not active for this request"
    );
}

#[test]
fn active_configuration_rejects_threshold_above_participant_count() {
    let opened_wallet = KeyPair::new();
    let wallet_public_key = opened_wallet.get_public_key().compress();

    let participant = KeyPair::new().get_public_key().to_address(false);
    let error = resolve_active_multisig_configuration(
        MultisigState::Active {
            participants: vec![participant],
            threshold: 2,
        },
        &wallet_public_key,
    )
    .unwrap_err();
    assert_eq!(error.to_string(), "Invalid multisig threshold");
}

#[test]
fn signing_configuration_fetches_daemon_state_for_request_source() {
    let source = KeyPair::new().get_public_key().to_address(false);
    let opened_wallet = KeyPair::new();
    let participant = opened_wallet.get_public_key().to_address(false);
    let fetch_called = Cell::new(false);

    let resolved = block_on(resolve_multisig_signing_configuration_with(
        &source.to_string(),
        &opened_wallet.get_public_key().compress(),
        |requested_source| {
            fetch_called.set(true);
            assert_eq!(requested_source, source);
            ready(Ok::<_, anyhow::Error>(MultisigState::Active {
                participants: vec![participant],
                threshold: 1,
            }))
        },
    ))
    .unwrap();

    assert!(fetch_called.get());
    assert_eq!(resolved.signer_id, Some(0));
}

#[test]
fn invalid_request_source_is_rejected_before_fetching_daemon_state() {
    let opened_wallet = KeyPair::new();
    let fetch_called = Cell::new(false);

    let error = block_on(resolve_multisig_signing_configuration_with(
        "invalid-address",
        &opened_wallet.get_public_key().compress(),
        |_| {
            fetch_called.set(true);
            ready(Ok::<_, anyhow::Error>(MultisigState::Deleted))
        },
    ))
    .unwrap_err();

    assert_eq!(error.to_string(), "Invalid multisig signing request source");
    assert!(!fetch_called.get());
}

#[test]
fn signing_configuration_propagates_daemon_fetch_error() {
    let source = KeyPair::new().get_public_key().to_address(false);
    let opened_wallet = KeyPair::new();

    let error = block_on(resolve_multisig_signing_configuration_with(
        &source.to_string(),
        &opened_wallet.get_public_key().compress(),
        |_| ready(Err(anyhow::anyhow!("daemon unavailable"))),
    ))
    .unwrap_err();

    assert_eq!(error.to_string(), "daemon unavailable");
}

#[test]
fn authorized_signing_binds_participant_id_and_signature_to_request_hash() {
    let signer = KeyPair::new();
    let request_hash = Hash::new([7; 32]);

    let share = create_authorized_multisig_signature_share(&request_hash, Some(3), |data| {
        signer.sign(data)
    })
    .unwrap();

    assert_eq!(share.request_hash, request_hash.to_hex());
    assert_eq!(share.signer_id, 3);
    let signature = Signature::from_hex(&share.signature).unwrap();
    assert!(signature.verify(request_hash.as_bytes(), signer.get_public_key()));
}

#[test]
fn unauthorized_wallet_is_rejected_before_any_signature_is_created() {
    let sign_called = Cell::new(false);

    let error = create_authorized_multisig_signature_share(&Hash::new([8; 32]), None, |_| {
        sign_called.set(true);
        KeyPair::new().sign(&[8; 32])
    })
    .unwrap_err();

    assert_eq!(
        error.to_string(),
        "The opened wallet is not an authorized participant for this multisig request"
    );
    assert!(!sign_called.get());
}
