use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Hash, KeyPair};
use xelis_common::transaction::builder::{TransactionTypeBuilder, TransferBuilder};

use crate::api::models::wallet_dtos::Transfer;

use super::*;

fn transfer_input(
    float_amount: f64,
    destination: String,
    asset: &Hash,
    extra_data: Option<&str>,
    encrypt_extra_data: Option<bool>,
) -> Transfer {
    Transfer {
        float_amount,
        str_address: destination,
        asset_hash: asset.to_hex(),
        extra_data: extra_data.map(str::to_owned),
        encrypt_extra_data,
    }
}

fn transfers_from(transaction_type: TransactionTypeBuilder) -> Vec<TransferBuilder> {
    let TransactionTypeBuilder::Transfers(transfers) = transaction_type else {
        panic!("expected a transfers transaction type");
    };

    transfers
}

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
fn transfer_builder_preserves_absent_extra_data_and_explicit_public_flag() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transfer = build_transfer(destination, 7, Hash::new([22; 32]), None, Some(false));

    assert!(transfer.extra_data.is_none());
    assert!(!transfer.encrypt_extra_data);
}

#[test]
fn transfer_input_uses_asset_precision_and_validates_the_destination() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([23; 32]);
    let transfer = build_transfer_from_input(
        transfer_input(
            1.25,
            destination.to_string(),
            &asset,
            Some("asset memo"),
            Some(false),
        ),
        asset.clone(),
        2,
    )
    .unwrap();

    assert_eq!(transfer.destination, destination);
    assert_eq!(transfer.asset, asset);
    assert_eq!(transfer.amount, 125);
    assert!(!transfer.encrypt_extra_data);
    assert!(matches!(
        transfer.extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "asset memo"
    ));

    let error = build_transfer_from_input(
        transfer_input(1.0, "invalid".to_owned(), &Hash::new([24; 32]), None, None),
        Hash::new([24; 32]),
        8,
    )
    .unwrap_err();

    assert!(error.to_string().starts_with("Invalid address"));
}

#[test]
fn transfer_input_rejects_amounts_that_do_not_match_asset_precision() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([25; 32]);
    let error = build_transfer_from_input(
        transfer_input(1.234, destination.to_string(), &asset, None, None),
        asset,
        2,
    )
    .unwrap_err();

    assert!(error
        .to_string()
        .starts_with("Error while converting amount to atomic format"));
}

#[tokio::test]
async fn multi_asset_transfers_preserve_order_amounts_and_independent_options() {
    let first_destination = KeyPair::new().get_public_key().to_address(false);
    let second_destination = KeyPair::new().get_public_key().to_address(false);
    let token = Hash::new([26; 32]);

    let transaction_type = create_transfers_with_decimals(
        vec![
            transfer_input(
                1.25,
                first_destination.to_string(),
                &XELIS_ASSET,
                Some("private"),
                None,
            ),
            transfer_input(
                2.5,
                second_destination.to_string(),
                &token,
                None,
                Some(false),
            ),
        ],
        |asset| async move {
            if asset == XELIS_ASSET {
                Ok(8)
            } else {
                Ok(2)
            }
        },
    )
    .await
    .unwrap();
    let transfers = transfers_from(transaction_type);

    assert_eq!(transfers.len(), 2);
    assert_eq!(transfers[0].destination, first_destination);
    assert_eq!(transfers[0].asset, XELIS_ASSET);
    assert_eq!(transfers[0].amount, 125_000_000);
    assert!(transfers[0].encrypt_extra_data);
    assert!(transfers[0].extra_data.is_some());
    assert_eq!(transfers[1].destination, second_destination);
    assert_eq!(transfers[1].asset, token);
    assert_eq!(transfers[1].amount, 250);
    assert!(!transfers[1].encrypt_extra_data);
    assert!(transfers[1].extra_data.is_none());
}

#[tokio::test]
async fn transfer_collection_stops_on_asset_metadata_failure() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let asset = Hash::new([31; 32]);
    let error = create_transfers_with_decimals(
        vec![transfer_input(
            1.25,
            destination.to_string(),
            &asset,
            None,
            None,
        )],
        |_| async { Err(anyhow::anyhow!("asset metadata missing")) },
    )
    .await
    .unwrap_err();

    assert!(error
        .to_string()
        .starts_with("Error while converting amount to atomic format"));
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
    for balance in [24, 25] {
        let error = amount_after_fee(balance, 25, &XELIS_ASSET, "insufficient").unwrap_err();

        assert_eq!(error.to_string(), "insufficient");
    }

    let token = Hash::new([27; 32]);
    assert_eq!(
        amount_after_fee(0, 25, &token, "insufficient")
            .unwrap_err()
            .to_string(),
        "insufficient"
    );
}

#[test]
fn transfer_all_uses_post_fee_xelis_amount_and_preserves_options() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transfers = transfers_from(
        build_transfer_all_type(
            destination.clone(),
            100,
            25,
            XELIS_ASSET,
            Some("all".to_owned()),
            Some(false),
        )
        .unwrap(),
    );

    assert_eq!(transfers.len(), 1);
    assert_eq!(transfers[0].destination, destination);
    assert_eq!(transfers[0].asset, XELIS_ASSET);
    assert_eq!(transfers[0].amount, 75);
    assert!(!transfers[0].encrypt_extra_data);
    assert!(matches!(
        &transfers[0].extra_data,
        Some(DataElement::Value(DataValue::String(value))) if value == "all"
    ));
}

#[test]
fn transfer_all_keeps_the_full_token_amount_because_fees_use_xelis() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let token = Hash::new([28; 32]);
    let transfers = transfers_from(
        build_transfer_all_type(destination, 100, 1_000, token.clone(), None, None).unwrap(),
    );

    assert_eq!(transfers[0].asset, token);
    assert_eq!(transfers[0].amount, 100);
}

#[test]
fn transfer_all_rejects_a_zero_post_fee_amount() {
    let destination = KeyPair::new().get_public_key().to_address(false);
    let error = build_transfer_all_type(destination, 25, 25, XELIS_ASSET, None, None).unwrap_err();

    assert_eq!(error.to_string(), "Insufficient balance for fees");
}

#[test]
fn burn_builders_preserve_asset_and_apply_all_fee_rules() {
    let token = Hash::new([29; 32]);
    let TransactionTypeBuilder::Burn(requested) = build_burn_type(token.clone(), 42) else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(requested.asset, token);
    assert_eq!(requested.amount, 42);

    let TransactionTypeBuilder::Burn(xelis_all) =
        build_burn_all_type(XELIS_ASSET, 100, 25).unwrap()
    else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(xelis_all.asset, XELIS_ASSET);
    assert_eq!(xelis_all.amount, 75);

    let TransactionTypeBuilder::Burn(token_all) =
        build_burn_all_type(token.clone(), 100, 1_000).unwrap()
    else {
        panic!("expected a burn transaction type");
    };
    assert_eq!(token_all.asset, token);
    assert_eq!(token_all.amount, 100);
}

#[test]
fn burn_all_rejects_a_zero_post_fee_amount() {
    let error = build_burn_all_type(XELIS_ASSET, 25, 25).unwrap_err();

    assert_eq!(
        error.to_string(),
        "Insufficient balance to pay burn transaction fees"
    );
}

#[test]
fn summary_serializes_the_final_post_fee_builder() {
    let hash = Hash::new([30; 32]);
    let destination = KeyPair::new().get_public_key().to_address(false);
    let transaction_type =
        build_transfer_all_type(destination, 100, 25, XELIS_ASSET, None, None).unwrap();
    let summary: serde_json::Value =
        serde_json::from_str(&transaction_summary_json(&hash, 25, transaction_type)).unwrap();

    assert_eq!(summary["hash"], hash.to_hex());
    assert_eq!(summary["fee"], 25);
    assert_eq!(summary["transaction_type"]["transfers"][0]["amount"], 75);
}
