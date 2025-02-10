use serde::{Deserialize, Serialize};
pub use xelis_common::transaction::builder::TransactionTypeBuilder;
pub use xelis_common::{api::DataElement, crypto::Address};

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SummaryTransaction {
    pub hash: String,
    pub fee: u64,
    pub transaction_type: TransactionTypeBuilder,
}

#[derive(Clone, Debug)]
pub struct Transfer {
    pub float_amount: f64,
    pub str_address: String,
    pub asset_hash: String,
    pub extra_data: Option<String>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct SignatureMultisig {
    pub id: u8,
    pub signature: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct MultisigDartPayload {
    pub threshold: u8,
    pub participants: Vec<ParticipantDartPayload>,
    pub topoheight: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ParticipantDartPayload {
    pub id: u8,
    pub address: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct IntegratedAddress {
    pub address: Address,
    pub data: Option<DataElement>,
}
