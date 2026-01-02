use std::collections::HashMap;

use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct XswdRequestSummary {
    pub event_type: XswdRequestType,
    pub application_info: AppInfo,
}

impl XswdRequestSummary {
    #[frb(ignore)]
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
    pub fn is_prefetch_permissions_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::PrefetchPermissions(_))
    }

    #[frb(sync)]
    pub fn is_app_disconnect(&self) -> bool {
        matches!(self.event_type, XswdRequestType::AppDisconnect)
    }

    #[frb(sync)]
    pub fn permission_json(&self) -> Option<String> {
        match &self.event_type {
            XswdRequestType::Permission(json) => Some(json.clone()),
            _ => None,
        }
    }

    #[frb(sync)]
    pub fn prefetch_permissions_json(&self) -> Option<String> {
        match &self.event_type {
            XswdRequestType::PrefetchPermissions(json) => Some(json.clone()),
            _ => None,
        }
    }
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct AppInfo {
    pub id: String,
    pub name: String,
    pub description: String,
    pub url: Option<String>,
    pub permissions: HashMap<String, PermissionPolicy>,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum XswdRequestType {
    Application,
    Permission(String),
    PrefetchPermissions(String),
    CancelRequest,
    AppDisconnect,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum PermissionPolicy {
    Ask,
    Accept,
    Reject,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum UserPermissionDecision {
    Accept,
    Reject,
    AlwaysAccept,
    AlwaysReject,
}

// Relay-specific types for XSWD client mode
#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct ApplicationDataRelayer {
    pub id: String,
    pub name: String,
    pub description: String,
    pub url: Option<String>,
    pub permissions: Vec<String>,
    pub relayer: String,
    pub encryption_mode: Option<EncryptionMode>,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum EncryptionMode {
    Aes { key: Vec<u8> },
    Chacha20Poly1305 { key: Vec<u8> },
}
