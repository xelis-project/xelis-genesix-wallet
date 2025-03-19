pub use flutter_rust_bridge::DartFnFuture;
use log::{error, info};
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
use xelis_wallet::api::PermissionResult;
pub use xelis_wallet::wallet::XSWDEvent;

use crate::api::dtos::{PermissionPolicy, XswdRequestType};

use super::dtos::{UserPermissionDecision, XswdRequestSummary};

pub async fn xswd_handler(
    mut receiver: UnboundedReceiver<XSWDEvent>,
    cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>,
    request_application_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<UserPermissionDecision>,
    request_permission_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<UserPermissionDecision>,
) {
    info!("XSWD Server has been enabled");
    while let Some(event) = receiver.recv().await {
        info!("Received XSWD event: {}", xswd_event_name(&event));
        match event {
            XSWDEvent::CancelRequest(state, callback) => {
                let permissions = state
                    .get_permissions()
                    .lock()
                    .await
                    .iter()
                    .map(|(key, permission)| {
                        let perm_type = match permission.get_id() {
                            0 => PermissionPolicy::Ask,
                            1 => PermissionPolicy::AlwaysAllow,
                            2 => PermissionPolicy::AlwaysDeny,
                            _ => unreachable!(
                                "Unknown permission ID encountered: {}",
                                permission.get_id()
                            ),
                        };
                        (key.clone(), perm_type)
                    })
                    .collect();

                let event_summary = XswdRequestSummary {
                    event_type: XswdRequestType::CancelRequest,
                    application_id: state.get_id().clone(),
                    application_name: state.get_name().clone(),
                    description: state.get_description().clone(),
                    url: state.get_url().clone(),
                    permissions: permissions,
                };

                cancel_request_dart_callback(event_summary.to_owned()).await;

                if callback.send(Ok(())).is_err() {
                    error!("Error while sending cancel response to XSWD");
                }
            }
            XSWDEvent::RequestApplication(app_state, signed, callback) => {
                let permissions = app_state
                    .get_permissions()
                    .lock()
                    .await
                    .iter()
                    .map(|(key, permission)| {
                        let perm_type = match permission.get_id() {
                            0 => PermissionPolicy::Ask,
                            1 => PermissionPolicy::AlwaysAllow,
                            2 => PermissionPolicy::AlwaysDeny,
                            _ => unreachable!(
                                "Unknown permission ID encountered: {}",
                                permission.get_id()
                            ),
                        };
                        (key.clone(), perm_type)
                    })
                    .collect();

                let event_summary = XswdRequestSummary {
                    event_type: XswdRequestType::Application(signed),
                    application_id: app_state.get_id().clone(),
                    application_name: app_state.get_name().clone(),
                    description: app_state.get_description().clone(),
                    url: app_state.get_url().clone(),
                    permissions: permissions,
                };

                let decision = request_application_dart_callback(event_summary.to_owned()).await;

                match decision {
                    UserPermissionDecision::Allow => {
                        if callback.send(Ok(PermissionResult::Allow)).is_err() {
                            error!("Error while sending application response to XSWD");
                        }
                    }
                    UserPermissionDecision::Deny => {
                        if callback.send(Ok(PermissionResult::Deny)).is_err() {
                            error!("Error while sending application response to XSWD");
                        }
                    }
                    _ => error!("Invalid decision for XSWD request application"),
                }
            }
            XSWDEvent::RequestPermission(app_state, request, callback) => {
                let permissions = app_state
                    .get_permissions()
                    .lock()
                    .await
                    .iter()
                    .map(|(key, permission)| {
                        let perm_type = match permission.get_id() {
                            0 => PermissionPolicy::Ask,
                            1 => PermissionPolicy::AlwaysAllow,
                            2 => PermissionPolicy::AlwaysDeny,
                            _ => unreachable!(
                                "Unknown permission ID encountered: {}",
                                permission.get_id()
                            ),
                        };
                        (key.clone(), perm_type)
                    })
                    .collect();

                let content = if let Some(params) = request.params {
                    format!("method: {}, params: {}", request.method, params)
                } else {
                    format!("method: {}", request.method)
                };

                let event_summary = XswdRequestSummary {
                    event_type: XswdRequestType::Permission(content),
                    application_id: app_state.get_id().clone(),
                    application_name: app_state.get_name().clone(),
                    description: app_state.get_description().clone(),
                    url: app_state.get_url().clone(),
                    permissions: permissions,
                };

                let decision = request_permission_dart_callback(event_summary.to_owned()).await;

                match decision {
                    UserPermissionDecision::Allow => {
                        if callback.send(Ok(PermissionResult::Allow)).is_err() {
                            error!("Error while sending permission response to XSWD");
                        }
                    }
                    UserPermissionDecision::Deny => {
                        if callback.send(Ok(PermissionResult::Deny)).is_err() {
                            error!("Error while sending permission response to XSWD");
                        }
                    }
                    UserPermissionDecision::AlwaysAllow => {
                        if callback.send(Ok(PermissionResult::AlwaysAllow)).is_err() {
                            error!("Error while sending permission response to XSWD");
                        }
                    }
                    UserPermissionDecision::AlwaysDeny => {
                        if callback.send(Ok(PermissionResult::AlwaysDeny)).is_err() {
                            error!("Error while sending permission response to XSWD");
                        }
                    }
                }
            }
        };
    }
}

fn xswd_event_name(event: &XSWDEvent) -> &'static str {
    match event {
        XSWDEvent::CancelRequest(_, _) => "CancelRequest",
        XSWDEvent::RequestApplication(_, _, _) => "RequestApplication",
        XSWDEvent::RequestPermission(_, _, _) => "RequestPermission",
    }
}
