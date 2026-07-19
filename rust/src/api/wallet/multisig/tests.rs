use xelis_common::api::{DataElement, DataValue};
use xelis_common::crypto::{Address, AddressType, KeyPair};

use super::{is_multisig_participant_address_valid, parse_multisig_participants};

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
