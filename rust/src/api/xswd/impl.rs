use indexmap::IndexMap;
use std::collections::HashMap;

use anyhow::{anyhow, bail, Context, Error, Result};
pub use flutter_rust_bridge::DartFnFuture;
use log::{debug, error, info};
pub use xelis_common::api::wallet::XSWDPrefetchPermissions;
use xelis_common::tokio::spawn_task;
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
pub use xelis_common::tokio::sync::oneshot::Sender;
#[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
use xelis_wallet::api::APIServer;
pub use xelis_wallet::api::AppState;
use xelis_wallet::api::{Permission, PermissionResult};
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
        _cancel_request_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>
            + Send
            + Sync
            + 'static,
        _request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        _request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        _request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>
            + Send
            + Sync
            + 'static,
        _app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<()>
            + Send
            + Sync
            + 'static,
    ) -> Result<()> {
        #[cfg(target_arch = "wasm32")]
        {
            let _ = (
                _cancel_request_dart_callback,
                _request_application_dart_callback,
                _request_permission_dart_callback,
                _request_prefetch_permissions_dart_callback,
                _app_disconnect_dart_callback,
            );
            bail!("Local XSWD server not supported on web. Use relay mode instead.");
        }

        #[cfg(all(not(target_arch = "wasm32"), not(feature = "api_server")))]
        {
            let _ = (
                _cancel_request_dart_callback,
                _request_application_dart_callback,
                _request_permission_dart_callback,
                _request_prefetch_permissions_dart_callback,
                _app_disconnect_dart_callback,
            );
            bail!("Local XSWD server not enabled in this build. Use relay mode instead.");
        }

        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            match self.get_wallet().enable_xswd().await {
                Ok(Some(receiver)) => {
                    spawn_task("xswd_handler", async move {
                        xswd_handler(
                            receiver,
                            _cancel_request_dart_callback,
                            _request_application_dart_callback,
                            _request_permission_dart_callback,
                            _request_prefetch_permissions_dart_callback,
                            _app_disconnect_dart_callback,
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
    }

    async fn stop_xswd(&self) -> Result<()> {
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let api_server = {
                let mut api_server = self.get_wallet().get_api_server().lock().await;
                api_server.take()
            };
            if let Some(api_server) = api_server {
                api_server.stop().await;
            }
        }

        let relayer = {
            let mut relayer = self.get_wallet().xswd_relayer().lock().await;
            relayer.take()
        };
        if let Some(relayer) = relayer {
            relayer.close().await;
        }
        Ok(())
    }

    async fn is_xswd_running(&self) -> bool {
        // Check if local XSWD server is running (native only)
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let lock = self.get_wallet().get_api_server().lock().await;
            if lock.is_some() {
                return true;
            }
            drop(lock);
        }

        // Check if there are any relayer connections (works on both native and web)
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let apps = relayer.applications().read().await;
            return !apps.is_empty();
        }

        false
    }

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>> {
        let mut apps = Vec::new();

        // Get applications from XSWD server (local connections - native only)
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
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
        }

        // Get applications from XSWD relayer (remote connections - works on both native and web)
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
        // Try XSWD server first (native only)
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
            let lock = self.get_wallet().get_api_server().lock().await;
            if let Some(api_server) = lock.as_ref() {
                if let APIServer::XSWD(xswd) = api_server {
                    let mut applications = xswd.get_handler().get_applications().write().await;
                    if let Some((_, app)) = applications.iter_mut().find(|(_, v)| v.get_id() == id)
                    {
                        return modify_app_permissions(app, &permissions).await;
                    }
                }
            }
            drop(lock);
        }

        // Try relayer if not found in XSWD server
        let relayer_lock = self.get_wallet().xswd_relayer().lock().await;
        if let Some(relayer) = relayer_lock.as_ref() {
            let relayer_apps = relayer.applications().read().await;
            if let Some((app, _)) = relayer_apps.iter().find(|(app, _)| app.get_id() == id) {
                return modify_app_permissions(app, &permissions).await;
            }
        }

        bail!("Application not found")
    }

    async fn close_application_session(&self, id: &String) -> Result<()> {
        // Try XSWD server first (native only)
        #[cfg(all(not(target_arch = "wasm32"), feature = "api_server"))]
        {
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
        }

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
        let encryption_mode = convert_encryption_mode(app_data.encryption_mode)?;

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

fn permission_from_policy(policy: &PermissionPolicy) -> Permission {
    match policy {
        PermissionPolicy::Accept => Permission::Allow,
        PermissionPolicy::Reject => Permission::Reject,
        PermissionPolicy::Ask => Permission::Ask,
    }
}

fn apply_permission_updates(
    current: &mut IndexMap<String, Permission>,
    updates: &HashMap<String, PermissionPolicy>,
) -> Result<()> {
    if updates.keys().any(|key| !current.contains_key(key)) {
        bail!("XSWD permission not found");
    }

    for (key, policy) in updates {
        if let Some(permission) = current.get_mut(key) {
            *permission = permission_from_policy(policy);
        }
    }

    Ok(())
}

async fn modify_app_permissions(
    app: &AppState,
    permissions: &HashMap<String, PermissionPolicy>,
) -> Result<()> {
    info!("Modifying XSWD application permissions");
    debug!("Updating {} XSWD permission policies", permissions.len());

    let mut current = app.get_permissions().lock().await;
    apply_permission_updates(&mut current, permissions)
}

fn encryption_key(key: Vec<u8>) -> Result<[u8; 32]> {
    let length = key.len();
    key.try_into().map_err(|_| {
        anyhow!("Invalid XSWD relayer encryption key length: expected 32 bytes, got {length}")
    })
}

fn convert_encryption_mode(mode: Option<EncryptionMode>) -> Result<Option<CoreEncryptionMode>> {
    mode.map(|mode| match mode {
        EncryptionMode::Aes { key } => Ok(CoreEncryptionMode::AES {
            key: encryption_key(key)?,
        }),
        EncryptionMode::Chacha20Poly1305 { key } => Ok(CoreEncryptionMode::Chacha20Poly1305 {
            key: encryption_key(key)?,
        }),
    })
    .transpose()
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
        handle_xswd_event(
            event,
            &cancel_request_dart_callback,
            &request_application_dart_callback,
            &request_permission_dart_callback,
            &request_prefetch_permissions_dart_callback,
            &app_disconnect_dart_callback,
        )
        .await;
    }
}

async fn handle_xswd_event<Cancel, Application, Request, Prefetch, Disconnect>(
    event: XSWDEvent,
    cancel_request_dart_callback: &Cancel,
    request_application_dart_callback: &Application,
    request_permission_dart_callback: &Request,
    request_prefetch_permissions_dart_callback: &Prefetch,
    app_disconnect_dart_callback: &Disconnect,
) where
    Cancel: Fn(XswdRequestSummary) -> DartFnFuture<()>,
    Application: Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>,
    Request: Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>,
    Prefetch: Fn(XswdRequestSummary) -> DartFnFuture<UserPermissionDecision>,
    Disconnect: Fn(XswdRequestSummary) -> DartFnFuture<()>,
{
    match event {
        XSWDEvent::CancelRequest(state, callback) => {
            let event_summary = create_event_summary(&state, XswdRequestType::CancelRequest).await;

            cancel_request_dart_callback(event_summary).await;

            if callback.send(Ok(())).is_err() {
                error!("Error while sending cancel response to XSWD");
            }
        }
        XSWDEvent::RequestApplication(state, callback) => {
            let event_summary = create_event_summary(&state, XswdRequestType::Application).await;

            let decision = request_application_dart_callback(event_summary).await;

            handle_permission_decision(decision, callback);
        }
        XSWDEvent::RequestPermission(state, request, callback) => {
            let json = match serde_json::to_string(&request)
                .context("Failed to serialize XSWD permission request")
            {
                Ok(json) => json,
                Err(error) => {
                    if callback.send(Err(error)).is_err() {
                        error!("Error while sending permission serialization failure to XSWD");
                    }
                    return;
                }
            };

            let event_summary =
                create_event_summary(&state, XswdRequestType::Permission(json)).await;

            let decision = request_permission_dart_callback(event_summary).await;

            handle_permission_decision(decision, callback);
        }
        XSWDEvent::PrefetchPermissions(state, permissions, callback) => {
            let json = match serde_json::to_string(&permissions)
                .context("Failed to serialize XSWD prefetch permissions request")
            {
                Ok(json) => json,
                Err(error) => {
                    if callback.send(Err(error)).is_err() {
                        error!("Error while sending prefetch serialization failure to XSWD");
                    }
                    return;
                }
            };

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
    }
}

async fn create_event_summary(state: &AppState, event_type: XswdRequestType) -> XswdRequestSummary {
    let application_info = create_app_info(state).await;
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
    let result = permission_result_from_decision(decision);

    if callback.send(Ok(result)).is_err() {
        error!("Error while sending permission response to XSWD");
    }
}

fn permission_result_from_decision(decision: UserPermissionDecision) -> PermissionResult {
    match decision {
        UserPermissionDecision::Accept => PermissionResult::Accept,
        UserPermissionDecision::Reject => PermissionResult::Reject,
        UserPermissionDecision::AlwaysAccept => PermissionResult::AlwaysAccept,
        UserPermissionDecision::AlwaysReject => PermissionResult::AlwaysReject,
    }
}

fn handle_prefetch_permissions_decision(
    decision: UserPermissionDecision,
    permissions: XSWDPrefetchPermissions,
    callback: Sender<Result<IndexMap<String, Permission>, Error>>,
) {
    let results = prefetch_permissions_from_decision(decision, permissions);

    if callback.send(Ok(results)).is_err() {
        error!("Error while sending prefetch permissions response back to XSWD");
    }
}

fn prefetch_permissions_from_decision(
    decision: UserPermissionDecision,
    permissions: XSWDPrefetchPermissions,
) -> IndexMap<String, Permission> {
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

    results
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

#[cfg(test)]
#[path = "impl/tests.rs"]
mod tests;
