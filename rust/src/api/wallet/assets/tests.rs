use serde_json::json;
use xelis_common::asset::{AssetData, AssetOwner, MaxSupplyMode};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::Hash;

use super::{asset_metadata_json, resolve_asset_hash};

#[test]
fn asset_metadata_serializes_every_field() {
    let origin = Hash::new([1; 32]);
    let owner = Hash::new([2; 32]);
    let data = AssetData::new(
        8,
        "Example Token".to_owned(),
        "EXT".to_owned(),
        MaxSupplyMode::Mintable(1_000_000),
        AssetOwner::Owner {
            origin: origin.clone(),
            origin_id: 7,
            owner: owner.clone(),
        },
    );

    let value: serde_json::Value =
        serde_json::from_str(&asset_metadata_json(&data).unwrap()).unwrap();

    assert_eq!(
        value,
        json!({
            "name": "Example Token",
            "ticker": "EXT",
            "decimals": 8,
            "max_supply": {"mintable": 1_000_000},
            "owner": {
                "owner": {
                    "origin": origin.to_hex(),
                    "origin_id": 7,
                    "owner": owner.to_hex(),
                }
            },
        })
    );
}

#[test]
fn asset_metadata_serializes_absent_owner_and_fixed_supply() {
    let data = AssetData::new(
        0,
        "Fixed".to_owned(),
        "FIX".to_owned(),
        MaxSupplyMode::Fixed(42),
        AssetOwner::None,
    );

    let value: serde_json::Value =
        serde_json::from_str(&asset_metadata_json(&data).unwrap()).unwrap();

    assert_eq!(value["max_supply"], json!({"fixed": 42}));
    assert_eq!(value["owner"], json!("none"));
}

#[test]
fn asset_hash_defaults_to_xelis_and_accepts_custom_assets() {
    let custom = Hash::new([3; 32]);

    assert_eq!(resolve_asset_hash(None).unwrap(), XELIS_ASSET);
    assert_eq!(resolve_asset_hash(Some(&custom.to_hex())).unwrap(), custom);
}

#[test]
fn asset_hash_rejects_invalid_hex() {
    let error = resolve_asset_hash(Some("not-a-hash")).unwrap_err();

    assert!(error.to_string().starts_with("Invalid asset"));
}
