use std::collections::HashMap;

use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
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
