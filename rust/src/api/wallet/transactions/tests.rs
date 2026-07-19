use anyhow::Error;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Hash, KeyPair};
use xelis_common::rpc::client::JsonRPCError;
use xelis_wallet::error::WalletError;

use super::{
    amount_after_fee, build_transfer, encrypt_extra_data_or_default, is_daemon_rejection,
    is_retryable_submit_error,
};

#[test]
fn encryption_defaults_to_enabled_and_respects_explicit_values() {
    assert!(encrypt_extra_data_or_default(None));
    assert!(encrypt_extra_data_or_default(Some(true)));
    assert!(!encrypt_extra_data_or_default(Some(false)));
}

#[test]
fn transfer_builder_maps_extra_data_and_encryption() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([3; 32]);
    let transfer = build_transfer(
        destination.clone(),
        42,
        asset.clone(),
        Some("memo".to_owned()),
        None,
    );

    assert_eq!(transfer.destination, destination);
    assert_eq!(transfer.amount, 42);
    assert_eq!(transfer.asset, asset);
    assert!(transfer.encrypt_extra_data);
    assert!(matches!(
        transfer.extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "memo"
    ));
}

#[test]
fn fee_is_deducted_only_from_the_native_asset() {
    assert_eq!(
        amount_after_fee(100, 25, &XELIS_ASSET, "insufficient").unwrap(),
        75
    );

    let token = Hash::new([4; 32]);
    assert_eq!(
        amount_after_fee(100, 200, &token, "insufficient").unwrap(),
        100
    );
}

#[test]
fn native_asset_fee_rejects_an_insufficient_balance() {
    let error = amount_after_fee(24, 25, &XELIS_ASSET, "insufficient").unwrap_err();

    assert_eq!(error.to_string(), "insufficient");
}

#[test]
fn daemon_server_errors_are_final_rejections() {
    let error = Error::new(JsonRPCError::ServerError {
        code: -32_000,
        message: "rejected".to_owned(),
        data: None,
    });

    assert!(is_daemon_rejection(&error));
    assert!(!is_retryable_submit_error(&WalletError::from(error)));
}

#[test]
fn transport_and_offline_errors_are_retryable() {
    let transport = WalletError::from(Error::new(JsonRPCError::ConnectionError(
        "offline".to_owned(),
    )));

    assert!(is_retryable_submit_error(&transport));
    assert!(is_retryable_submit_error(&WalletError::NotOnlineMode));
    assert!(is_retryable_submit_error(&WalletError::NoNetworkHandler));
}

#[test]
fn unrelated_wallet_errors_are_not_retryable() {
    assert!(!is_retryable_submit_error(
        &WalletError::InvalidAddressParams
    ));
}
