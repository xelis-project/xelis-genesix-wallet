use std::collections::HashMap;
use indexmap::IndexMap;

use anyhow::{bail, Error, Result};
pub use flutter_rust_bridge::DartFnFuture;
use log::{debug, error, info};
use xelis_common::tokio::spawn_task;
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
pub use xelis_common::tokio::sync::oneshot::Sender;
pub use xelis_wallet::api::AppState;
use xelis_wallet::api::{APIServer, Permission, InternalPrefetchPermissions, PermissionResult};
pub use xelis_wallet::wallet::XSWDEvent;


use crate::api::{
    models::xswd_dtos::{
        AppInfo, PermissionPolicy, UserPermissionDecision, XswdRequestSummary, XswdRequestType,
    },
    wallet::XelisWallet,
};

#[allow(async_fn_in_trait)]
pub trait XSWD {
    async fn start_xswd(
        &self,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>
            + Send
            + Sync
            + 'static,
    ) -> Result<()>;

    async fn stop_xswd(&self) -> Result<()>;

    async fn is_xswd_running(&self) -> bool;

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>>;

    async fn modify_application_permissions(
        &self,
        id: &String,
        permissions: HashMap<String, PermissionPolicy>,
    ) -> Result<()>;

    async fn close_application_session(&self, id: &String) -> Result<()>;
}

impl XSWD for XelisWallet {
    async fn start_xswd(
        &self,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>
            + Send
            + Sync
            + 'static,
    ) -> Result<()> {
        match self.get_wallet().enable_xswd().await {
            Ok(Some(receiver)) => {
                spawn_task("xswd_handler", async move {
                    xswd_handler(
                        receiver,
                        cancel_request_dart_callback,
                        request_application_dart_callback,
                        request_permission_dart_callback,
                        request_prefetch_permissions_dart_callback,
                        app_disconnect_dart_callback,
                    )
                    .await;
                });
            }
            Ok(None) => bail!("Failed to enable XSWD Server: receiver is None"),
            Err(e) => bail!("Error while enabling XSWD Server: {}", e),
        };
        Ok(())
    }

    async fn stop_xswd(&self) -> Result<()> {
        self.get_wallet().stop_api_server().await?;
        Ok(())
    }

    async fn is_xswd_running(&self) -> bool {
        let lock = self.get_wallet().get_api_server().lock().await;
        lock.is_some()
    }

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>> {
        let lock = self.get_wallet().get_api_server().lock().await;
        let api_server: &xelis_wallet::api::APIServer<
            std::sync::Arc<xelis_wallet::wallet::Wallet>,
        > = lock
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("API Server is not running"))?;
        match api_server {
            APIServer::XSWD(xswd) => {
                let applications = xswd.get_handler().get_applications().read().await;
                let mut apps = Vec::new();
                for (_, app) in applications.iter() {
                    let app_info = create_app_info(app).await;
                    apps.push(app_info);
                }
                Ok(apps)
            }
            _ => bail!("API Server is not XSWD"),
        }
    }

    async fn modify_application_permissions(
        &self,
        id: &String,
        permissions: HashMap<String, PermissionPolicy>,
    ) -> Result<()> {
        let lock = self.get_wallet().get_api_server().lock().await;
        let api_server = lock
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("API Server is not running"))?;

        match api_server {
            APIServer::XSWD(xswd) => {
                let app_exists = {
                    let applications = xswd.get_handler().get_applications().read().await;
                    applications.iter().any(|(_, v)| v.get_id() == id)
                };

                if !app_exists {
                    bail!("Application not found");
                }

                let mut applications = xswd.get_handler().get_applications().write().await;
                let app = applications
                    .iter_mut()
                    .find(|(_, v)| v.get_id() == id)
                    .ok_or_else(|| anyhow::anyhow!("Application not found"))?
                    .1;

                info!("Modifying permissions for application: {}", app.get_name());
                debug!("New permissions: {:?}", permissions);

                let mut inner_permissions = app.get_permissions().lock().await;
                for (key, value) in permissions.iter() {
                    if let Some(entry) = inner_permissions.get_mut(key) {
                        match value {
                            PermissionPolicy::Accept => {
                                *entry = Permission::Allow;
                            }
                            PermissionPolicy::Reject => {
                                *entry = Permission::Reject;
                            }
                            PermissionPolicy::Ask => {
                                *entry = Permission::Ask;
                            }
                        }
                    } else {
                        bail!(format!("Permission {} not found", key));
                    }
                }
                Ok(())
            }
            _ => bail!("API Server is not XSWD"),
        }
    }

    async fn close_application_session(&self, id: &String) -> Result<()> {
        let lock = self.get_wallet().get_api_server().lock().await;
        let api_server = lock
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("API Server is not running"))?;

        match api_server {
            APIServer::XSWD(xswd) => {
                let app_exists = {
                    let applications = xswd.get_handler().get_applications().read().await;
                    applications.iter().any(|(_, v)| v.get_id() == id)
                };

                if !app_exists {
                    bail!("Application not found");
                }

                let removed_session = {
                    let mut applications = xswd.get_handler().get_applications().write().await;
                    let mut removed_key = None;
                    applications.retain(|k, v| {
                        if v.get_id() == id {
                            removed_key = Some(k.clone());
                            false
                        } else {
                            true
                        }
                    });
                    removed_key
                };

                if let Some(session) = removed_session {
                    session.close(None).await?;
                } else {
                    bail!("Failed to close application session");
                }

                Ok(())
            }
            _ => bail!("API Server is not XSWD"),
        }
    }
}

pub async fn xswd_handler(
    mut receiver: UnboundedReceiver<XSWDEvent>,
    cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>,
    request_application_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<UserPermissionDecision>,
    request_permission_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<UserPermissionDecision>,
    request_prefetch_permissions_dart_callback: impl Fn(
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
            },
            XSWDEvent::PrefetchPermissions(state, permissions, callback) => {
                let json = serde_json::to_string(&permissions)
                    .expect("Failed to serialize prefetch permissions request");

                let event_summary =
                    create_event_summary(&state, XswdRequestType::PrefetchPermissions(json)).await;

                let decision = request_prefetch_permissions_dart_callback(event_summary).await;

                handle_prefetch_permissions_decision(decision, permissions, callback);
            },
            XSWDEvent::AppDisconnect(app_state) => {
                let event_summary =
                    create_event_summary(&app_state, XswdRequestType::AppDisconnect).await;

                app_disconnect_dart_callback(event_summary).await;
            },
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
        id: state.get_id().to_string(),
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

fn handle_prefetch_permissions_decision(
    decision: UserPermissionDecision,
    permissions: InternalPrefetchPermissions,
    callback: Sender<Result<IndexMap<String, Permission>, Error>>,
) {
    let accepted = matches!(
        decision,
        UserPermissionDecision::Accept | UserPermissionDecision::AlwaysAccept
    );

    let mut results: IndexMap<String, Permission> = IndexMap::new();
    if accepted {
        for p in permissions.permissions {
            results.insert(p, Permission::Allow);
        }
    }

    if callback.send(Ok(results)).is_err() {
        error!("Error while sending prefetch permissions response back to XSWD");
    }
}

fn xswd_event_name(event: &XSWDEvent) -> &'static str {
    match event {
        XSWDEvent::CancelRequest(_, _) => "CancelRequest",
        XSWDEvent::RequestApplication(_, _) => "RequestApplication",
        XSWDEvent::RequestPermission(_, _, _) => "RequestPermission",
        XSWDEvent::PrefetchPermissions(_, _, _) => "PrefetchPermissions",
        XSWDEvent::AppDisconnect(_) => "AppDisconnect",
    }
}
