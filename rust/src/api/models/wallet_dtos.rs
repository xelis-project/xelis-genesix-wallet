use std::borrow::Cow;

use anyhow::{ensure, Context, Result};
use flutter_rust_bridge::frb;

use serde::{Deserialize, Serialize};
use xelis_common::asset::{AssetOwner, MaxSupplyMode};
use xelis_common::crypto::Hash;
use xelis_common::serializer::Serializer;
pub use xelis_common::transaction::builder::TransactionTypeBuilder;
pub use xelis_common::{api::DataElement, crypto::Address};
use xelis_wallet::storage::TransactionFilterOptions;

#[frb]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum BroadcastTransactionOutcome {
    Submitted,
    Retryable,
    Rejected,
    LocalFailure,
    SubmittedNeedsResync,
}

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
#[serde(rename_all = "snake_case")]
#[frb(dart_metadata=("freezed"))]
pub enum MultisigSigningTransaction {
    Transfers {
        transfers: Vec<MultisigSigningTransfer>,
    },
    Burn {
        asset: String,
        amount: u64,
    },
    DeleteMultisig,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct MultisigSigningTransfer {
    pub amount: u64,
    pub asset: String,
    pub destination: String,
    pub has_extra_data: bool,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct MultisigSigningRequest {
    /// Canonical request envelope to share with each participant.
    pub encoded: String,
    /// Hash recomputed from the canonical unsigned transaction.
    pub hash: String,
    pub source: String,
    pub network: String,
    pub fee: u64,
    pub fee_limit: u64,
    pub nonce: u64,
    pub reference_topoheight: u64,
    pub threshold: u8,
    pub participants: Vec<ParticipantDartPayload>,
    /// Present when the currently opened wallet is an authorized signer.
    pub signer_id: Option<u8>,
    pub transaction: MultisigSigningTransaction,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct MultisigSignatureShare {
    /// Canonical signature envelope to return to the request creator.
    pub encoded: String,
    pub request_hash: String,
    pub signer_id: u8,
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
    pub accept_blob: bool,
    pub min_timestamp: Option<u64>,
    pub max_timestamp: Option<u64>,
}

impl HistoryPageFilter {
    pub fn options<'a>(&'a self) -> Result<TransactionFilterOptions<'a>> {
        ensure!(self.page > 0, "Page must be at least 1");
        if let Some(limit) = self.limit {
            ensure!(limit > 0, "Limit cannot be 0");
        }

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
            accept_blob: self.accept_blob && self.address.is_none() && self.asset_hash.is_none(),
            accept_burn: match self.address {
                Some(_) => false,
                None => self.accept_burn,
            },
            min_timestamp: self.min_timestamp,
            max_timestamp: self.max_timestamp,
            skip: match self.limit {
                Some(limit) => Some(
                    self.page
                        .checked_sub(1)
                        .and_then(|page| page.checked_mul(limit))
                        .context("Pagination offset is too large")?,
                ),
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

impl From<MaxSupplyMode> for XelisMaxSupplyMode {
    fn from(value: MaxSupplyMode) -> Self {
        match value {
            MaxSupplyMode::None => Self::None,
            MaxSupplyMode::Fixed(max_supply) => Self::Fixed(max_supply),
            MaxSupplyMode::Mintable(max_supply) => Self::Mintable(max_supply),
        }
    }
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

impl From<&AssetOwner> for XelisAssetOwner {
    fn from(value: &AssetOwner) -> Self {
        match value {
            AssetOwner::None => Self::None,
            AssetOwner::Creator { contract, id } => Self::Creator {
                contract: contract.to_hex(),
                id: *id,
            },
            AssetOwner::Owner {
                origin,
                origin_id,
                owner,
            } => Self::Owner {
                origin: origin.to_hex(),
                origin_id: *origin_id,
                owner: owner.to_hex(),
            },
        }
    }
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
