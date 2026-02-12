use std::borrow::Cow;

use anyhow::{Context, Result};
use flutter_rust_bridge::frb;

use serde::{Deserialize, Serialize};
use xelis_common::crypto::Hash;
use xelis_common::serializer::Serializer;
pub use xelis_common::transaction::builder::TransactionTypeBuilder;
pub use xelis_common::{api::DataElement, crypto::Address};
use xelis_wallet::storage::TransactionFilterOptions;

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct SummaryTransaction {
    pub hash: String,
    pub fee: u64,
    pub transaction_type: TransactionTypeBuilder,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct Transfer {
    pub float_amount: f64,
    pub str_address: String,
    pub asset_hash: String,
    pub extra_data: Option<String>,
    pub encrypt_extra_data: Option<bool>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct SignatureMultisig {
    pub id: u8,
    pub signature: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct MultisigDartPayload {
    pub threshold: u8,
    pub participants: Vec<ParticipantDartPayload>,
    pub topoheight: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct ParticipantDartPayload {
    pub id: u8,
    pub address: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct IntegratedAddress {
    pub address: Address,
    pub data: Option<DataElement>,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct HistoryPageFilter {
    pub page: usize,
    pub limit: Option<usize>,
    pub asset_hash: Option<String>,
    pub address: Option<String>,
    pub min_topoheight: Option<u64>,
    pub max_topoheight: Option<u64>,
    pub accept_incoming: bool,
    pub accept_outgoing: bool,
    pub accept_coinbase: bool,
    pub accept_burn: bool,
    pub min_timestamp: Option<u64>,
    pub max_timestamp: Option<u64>,
}

impl HistoryPageFilter {
    pub fn options<'a>(&'a self) -> Result<TransactionFilterOptions<'a>> {
        let address = match self.address.as_ref() {
            Some(address) => {
                let address = Address::from_string(&address).context("Invalid address")?;
                Some(Cow::Owned(address.to_public_key()))
            }
            None => None,
        };

        let asset = match self.asset_hash.as_ref() {
            Some(asset_hash) => Some(Cow::Owned(
                Hash::from_hex(&asset_hash).context("Invalid asset")?,
            )),
            None => None,
        };

        Ok(TransactionFilterOptions {
            address,
            asset,
            min_topoheight: self.min_topoheight,
            max_topoheight: self.max_topoheight,
            accept_incoming: self.accept_incoming,
            accept_outgoing: self.accept_outgoing,
            accept_coinbase: match self.address {
                Some(_) => false,
                None => self.accept_coinbase,
            },
            accept_burn: match self.address {
                Some(_) => false,
                None => self.accept_burn,
            },
            min_timestamp: self.min_timestamp,
            max_timestamp: self.max_timestamp,
            skip: match self.limit {
                Some(limit) => Some((self.page - 1) * limit),
                None => None,
            },
            limit: self.limit,
            query: None,
        })
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
#[frb(dart_metadata=("freezed"))]
pub enum XelisMaxSupplyMode {
    None,
    Fixed(u64),
    Mintable(u64),
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
#[frb(dart_metadata=("freezed"))]
pub enum XelisAssetOwner {
    None,
    Creator {
        contract: String,
        id: u64,
    },
    Owner {
        origin: String,
        origin_id: u64,
        owner: String,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct XelisAssetMetadata {
    pub name: String,
    pub ticker: String,
    pub decimals: u8,
    pub max_supply: XelisMaxSupplyMode,
    pub owner: Option<XelisAssetOwner>,
}
