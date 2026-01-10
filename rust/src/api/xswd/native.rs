use indexmap::IndexMap;
use std::collections::HashMap;

use anyhow::{bail, Error, Result};
pub use flutter_rust_bridge::DartFnFuture;
use log::{debug, error, info};
use xelis_common::tokio::spawn_task;
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
pub use xelis_common::tokio::sync::oneshot::Sender;
pub use xelis_wallet::api::AppState;
use xelis_wallet::api::{APIServer, InternalPrefetchPermissions, Permission, PermissionResult};
pub use xelis_wallet::wallet::XSWDEvent;

use crate::api::{
    models::xswd_dtos::{
        AppInfo, ApplicationDataRelayer, EncryptionMode, PermissionPolicy, UserPermissionDecision,
        XswdRequestSummary, XswdRequestType,
    },
    wallet::XelisWallet,
};
use xelis_wallet::api::{
    ApplicationData, ApplicationDataRelayer as CoreApplicationDataRelayer,
    EncryptionMode as CoreEncryptionMode,
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

    async fn add_xswd_relayer(
        &self,
        app_data: ApplicationDataRelayer,
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
            Ok(None) => {
                // XSWD server is already running, this is not an error
            }
            Err(e) => bail!("Error while enabling XSWD Server: {}", e),
        };
        Ok(())
    }

    async fn stop_xswd(&self) -> Result<()> {
        self.get_wallet().stop_api_server().await?;
        Ok(())
    }

    async fn is_xswd_running(&self) -> bool {
        // Check if local XSWD server is running
        let lock = self.get_wallet().get_api_server().lock().await;
        if lock.is_some() {
            return true;
        }
        drop(lock);

        // Check if there are any relayer connections
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let apps = relayer.applications().read().await;
            return !apps.is_empty();
        }

        false
    }

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>> {
        let mut apps = Vec::new();

        // Get applications from XSWD server (local connections)
        let lock = self.get_wallet().get_api_server().lock().await;
        if let Some(api_server) = lock.as_ref() {
            match api_server {
                APIServer::XSWD(xswd) => {
                    let applications = xswd.get_handler().get_applications().read().await;
                    for (_, app) in applications.iter() {
                        let app_info = create_app_info(app).await;
                        apps.push(app_info);
                    }
                }
                _ => {}
            }
        }

        // Get applications from XSWD relayer (remote connections)
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let relayer_apps = relayer.applications().read().await;
            for (app, _) in relayer_apps.iter() {
                let mut app_info = create_app_info(app).await;
                // Mark as relayer connection
                app_info.is_relayer = true;
                apps.push(app_info);
            }
        }

        Ok(apps)
    }

    async fn modify_application_permissions(
        &self,
        id: &String,
        permissions: HashMap<String, PermissionPolicy>,
    ) -> Result<()> {
        // Helper function to modify permissions
        async fn modify_perms(
            app: &AppState,
            permissions: &HashMap<String, PermissionPolicy>,
        ) -> Result<()> {
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

        // Try XSWD server first
        let lock = self.get_wallet().get_api_server().lock().await;
        if let Some(api_server) = lock.as_ref() {
            if let APIServer::XSWD(xswd) = api_server {
                let mut applications = xswd.get_handler().get_applications().write().await;
                if let Some((_, app)) = applications.iter_mut().find(|(_, v)| v.get_id() == id) {
                    return modify_perms(app, &permissions).await;
                }
            }
        }
        drop(lock);

        // Try relayer if not found in XSWD server
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let relayer_apps = relayer.applications().read().await;
            if let Some((app, _)) = relayer_apps.iter().find(|(app, _)| app.get_id() == id) {
                return modify_perms(app, &permissions).await;
            }
        }

        bail!("Application not found")
    }

    async fn close_application_session(&self, id: &String) -> Result<()> {
        // Try XSWD server first
        let lock = self.get_wallet().get_api_server().lock().await;
        if let Some(api_server) = lock.as_ref() {
            if let APIServer::XSWD(xswd) = api_server {
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
                    return Ok(());
                }
            }
        }
        drop(lock);

        // Try relayer if not found in XSWD server
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let app_state = {
                let relayer_apps = relayer.applications().read().await;
                relayer_apps
                    .iter()
                    .find(|(app, _)| app.get_id() == id)
                    .map(|(app, _)| app.clone())
            };

            if let Some(app) = app_state {
                relayer.on_close(app).await;
                return Ok(());
            }
        }

        bail!("Application not found")
    }

    async fn add_xswd_relayer(
        &self,
        app_data: ApplicationDataRelayer,
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
        // Convert DTO to core ApplicationDataRelayer
        let encryption_mode = app_data.encryption_mode.map(|mode| match mode {
            EncryptionMode::Aes { key } => {
                let mut key_array = [0u8; 32];
                key_array.copy_from_slice(&key[..32]);
                CoreEncryptionMode::AES { key: key_array }
            }
            EncryptionMode::Chacha20Poly1305 { key } => {
                let mut key_array = [0u8; 32];
                key_array.copy_from_slice(&key[..32]);
                CoreEncryptionMode::Chacha20Poly1305 { key: key_array }
            }
        });

        // Use serde to construct ApplicationData since fields are private
        let app_data_json = serde_json::json!({
            "id": app_data.id,
            "name": app_data.name,
            "description": app_data.description,
            "url": app_data.url,
            "permissions": app_data.permissions,
        });
        let core_app_info: ApplicationData = serde_json::from_value(app_data_json)?;

        let core_app_data = CoreApplicationDataRelayer {
            app_data: core_app_info,
            relayer: app_data.relayer,
            encryption_mode,
        };

        // Initialize relayer infrastructure (without adding application yet)
        match self.get_wallet().init_xswd_relayer().await? {
            Some(receiver) => {
                info!("XSWD relayer created new channel - spawning event handler");
                // Spawn handler BEFORE adding application so it can respond to events
                spawn_task(
                    "xswd-relayer-handler",
                    xswd_handler(
                        receiver,
                        cancel_request_dart_callback,
                        request_application_dart_callback,
                        request_permission_dart_callback,
                        request_prefetch_permissions_dart_callback,
                        app_disconnect_dart_callback,
                    ),
                );

                // Now add application - handler is ready to process RequestApplication event
                self.get_wallet()
                    .add_xswd_relayer_application(core_app_data)
                    .await?;
            }
            None => {
                info!("XSWD relayer using existing event handler from startXSWD");
                // Handler already running, safe to add application
                self.get_wallet()
                    .add_xswd_relayer_application(core_app_data)
                    .await?;
            }
        }
        Ok(())
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
            }
            XSWDEvent::PrefetchPermissions(state, permissions, callback) => {
                let json = serde_json::to_string(&permissions)
                    .expect("Failed to serialize prefetch permissions request");

                let event_summary =
                    create_event_summary(&state, XswdRequestType::PrefetchPermissions(json)).await;

                let decision = request_prefetch_permissions_dart_callback(event_summary).await;

                handle_prefetch_permissions_decision(decision, permissions, callback);
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
        id: state.get_id().to_string(),
        name: state.get_name().clone(),
        description: state.get_description().clone(),
        url: state.get_url().clone(),
        permissions,
        is_relayer: false,
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
