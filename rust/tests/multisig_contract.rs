use rust_lib::api::models::wallet_dtos::{
    MultisigSigningRequest, MultisigSigningTransaction, MultisigSigningTransfer,
    ParticipantDartPayload,
};
use serde_json::json;

#[test]
fn multisig_signing_request_round_trips_through_the_public_contract() {
    let request = MultisigSigningRequest {
        encoded: "canonical-request".to_owned(),
        hash: "11".repeat(32),
        source: "source-address".to_owned(),
        network: "testnet".to_owned(),
        fee: 1_000,
        fee_limit: 2_000,
        nonce: 7,
        reference_topoheight: 42,
        threshold: 2,
        participants: vec![
            ParticipantDartPayload {
                id: 0,
                address: "participant-one".to_owned(),
            },
            ParticipantDartPayload {
                id: 1,
                address: "participant-two".to_owned(),
            },
        ],
        signer_id: Some(1),
        transaction: MultisigSigningTransaction::Transfers {
            transfers: vec![MultisigSigningTransfer {
                amount: 125_000_000,
                asset: "22".repeat(32),
                destination: "destination-address".to_owned(),
                has_extra_data: true,
            }],
        },
    };

    let encoded = serde_json::to_value(&request).expect("public request should serialize");
    assert_eq!(
        encoded["transaction"],
        json!({
            "transfers": {
                "transfers": [{
                    "amount": 125_000_000,
                    "asset": "22".repeat(32),
                    "destination": "destination-address",
                    "has_extra_data": true
                }]
            }
        })
    );

    let decoded: MultisigSigningRequest =
        serde_json::from_value(encoded).expect("public request should deserialize");
    assert_eq!(decoded.threshold, 2);
    assert_eq!(decoded.signer_id, Some(1));
    assert_eq!(decoded.participants.len(), 2);
    assert!(matches!(
        decoded.transaction,
        MultisigSigningTransaction::Transfers { transfers }
            if transfers.len() == 1
                && transfers[0].amount == 125_000_000
                && transfers[0].has_extra_data
    ));
}

#[test]
fn multisig_transaction_variants_keep_their_public_serialization_tags() {
    let burn = serde_json::to_value(MultisigSigningTransaction::Burn {
        asset: "asset".to_owned(),
        amount: 7,
    })
    .expect("burn transaction should serialize");
    let delete = serde_json::to_value(MultisigSigningTransaction::DeleteMultisig)
        .expect("delete transaction should serialize");

    assert_eq!(burn, json!({"burn": {"asset": "asset", "amount": 7}}));
    assert_eq!(delete, json!("delete_multisig"));
}
