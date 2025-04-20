use anyhow::{Error, Result};
pub use flutter_rust_bridge::DartFnFuture;
use log::{error, info};
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
pub use xelis_common::tokio::sync::oneshot::Sender;
pub use xelis_wallet::api::AppState;
use xelis_wallet::api::{Permission, PermissionResult};
pub use xelis_wallet::wallet::XSWDEvent;

use super::models::xswd_dtos::{
    AppInfo, PermissionPolicy, UserPermissionDecision, XswdRequestSummary, XswdRequestType,
};

pub async fn xswd_handler(
    mut receiver: UnboundedReceiver<XSWDEvent>,
    cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>,
    request_application_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<UserPermissionDecision>,
    request_permission_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<UserPermissionDecision>,
    app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>,
) {
    info!("XSWD Server has been enabled");
    while let Some(event) = receiver.recv().await {
        info!("Received XSWD event: {}", xswd_event_name(&event));
        match event {
            XSWDEvent::CancelRequest(state, callback) => {
                let event_summary =
                    create_event_summary(&state, XswdRequestType::CancelRequest).await;

                cancel_request_dart_callback(event_summary.to_owned()).await;

                if callback.send(Ok(())).is_err() {
                    error!("Error while sending cancel response to XSWD");
                }
            }
            XSWDEvent::RequestApplication(state, callback) => {
                let event_summary =
                    create_event_summary(&state, XswdRequestType::Application).await;

                let decision = request_application_dart_callback(event_summary).await;

                handle_permission_decision(decision, callback);
            }
            XSWDEvent::RequestPermission(state, request, callback) => {
                let json = serde_json::to_string(&request).expect("Failed to serialize request");
                info!("Request: {}", json);

                let event_summary =
                    create_event_summary(&state, XswdRequestType::Permission(json)).await;

                let decision = request_permission_dart_callback(event_summary).await;

                handle_permission_decision(decision, callback);
            }
            XSWDEvent::AppDisconnect(app_state) => {
                let event_summary =
                    create_event_summary(&app_state, XswdRequestType::AppDisconnect).await;

                app_disconnect_dart_callback(event_summary).await;
            }
        };
    }
}

async fn create_event_summary(state: &AppState, event_type: XswdRequestType) -> XswdRequestSummary {
    let application_info = create_app_info(state).await;
    info!("application_info: {:?}", application_info);
    XswdRequestSummary::new(event_type, application_info)
}

pub async fn create_app_info(state: &AppState) -> AppInfo {
    let lock = state.get_permissions().lock().await;
    let permissions = lock
        .iter()
        .map(|(key, permission)| {
            let permission_policy = match permission {
                Permission::Ask => PermissionPolicy::Ask,
                Permission::Allow => PermissionPolicy::Accept,
                Permission::Reject => PermissionPolicy::Reject,
            };
            (key.clone(), permission_policy)
        })
        .collect();

    AppInfo {
        id: state.get_id().clone(),
        name: state.get_name().clone(),
        description: state.get_description().clone(),
        url: state.get_url().clone(),
        permissions,
    }
}

fn handle_permission_decision(
    decision: UserPermissionDecision,
    callback: Sender<Result<PermissionResult, Error>>,
) {
    let result = match decision {
        UserPermissionDecision::Accept => PermissionResult::Accept,
        UserPermissionDecision::Reject => PermissionResult::Reject,
        UserPermissionDecision::AlwaysAccept => PermissionResult::AlwaysAccept,
        UserPermissionDecision::AlwaysReject => PermissionResult::AlwaysReject,
    };

    if callback.send(Ok(result)).is_err() {
        error!("Error while sending permission response to XSWD");
    }
}

fn xswd_event_name(event: &XSWDEvent) -> &'static str {
    match event {
        XSWDEvent::CancelRequest(_, _) => "CancelRequest",
        XSWDEvent::RequestApplication(_, _) => "RequestApplication",
        XSWDEvent::RequestPermission(_, _, _) => "RequestPermission",
        XSWDEvent::AppDisconnect(_) => "AppDisconnect",
    }
}
