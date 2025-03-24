use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
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
    pub encrypt_extra_data: Option<bool>,
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

#[derive(Clone, Debug)]
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
}

#[derive(Clone, Debug)]
pub struct XswdRequestSummary {
    pub event_type: XswdRequestType,
    pub application_info: AppInfo,
}

impl XswdRequestSummary {
    pub fn new(event_type: XswdRequestType, application_info: AppInfo) -> Self {
        Self {
            event_type,
            application_info,
        }
    }

    #[frb(sync)]
    pub fn is_cancel_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::CancelRequest)
    }

    #[frb(sync)]
    pub fn is_application_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::Application)
    }

    #[frb(sync)]
    pub fn is_permission_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::Permission(_))
    }

    #[frb(sync)]
    pub fn is_app_disconnect(&self) -> bool {
        matches!(self.event_type, XswdRequestType::AppDisconnect)
    }
}

#[derive(Clone, Debug)]
pub struct AppInfo {
    pub id: String,
    pub name: String,
    pub description: String,
    pub url: Option<String>,
    pub permissions: HashMap<String, PermissionPolicy>,
}

#[derive(Clone, Debug)]
pub enum XswdRequestType {
    Application,
    Permission(String),
    CancelRequest,
    AppDisconnect,
}

#[derive(Clone, Debug)]
pub enum PermissionPolicy {
    Ask,
    Accept,
    Reject,
}

#[derive(Clone, Debug)]
pub enum UserPermissionDecision {
    Accept,
    Reject,
    AlwaysAccept,
    AlwaysReject,
}
