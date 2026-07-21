use std::sync::{Arc, Mutex};

use indexmap::{IndexMap, IndexSet};
use serde_json::json;
use xelis_common::rpc::RpcRequest;
use xelis_common::tokio::sync::{mpsc, oneshot};

use super::*;

fn app_state() -> Arc<AppState> {
    let data: ApplicationData = serde_json::from_value(json!({
        "id": "app-id",
        "name": "Test app",
        "description": "Test description",
        "url": "https://example.com",
        "permissions": ["get_balance", "build_transaction"]
    }))
    .unwrap();

    Arc::new(AppState::new(data))
}

fn prefetch_permissions() -> XSWDPrefetchPermissions {
    XSWDPrefetchPermissions {
        reason: Some("Prepare account view".to_owned()),
        permissions: IndexSet::from_iter(["get_balance".to_owned(), "get_assets".to_owned()]),
    }
}

#[test]
fn permission_decisions_map_to_the_exact_core_result() {
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::Accept),
        PermissionResult::Accept
    ));
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::Reject),
        PermissionResult::Reject
    ));
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::AlwaysAccept),
        PermissionResult::AlwaysAccept
    ));
    assert!(matches!(
        permission_result_from_decision(UserPermissionDecision::AlwaysReject),
        PermissionResult::AlwaysReject
    ));
}

#[test]
fn prefetch_acceptance_allows_every_requested_permission_in_order() {
    for decision in [
        UserPermissionDecision::Accept,
        UserPermissionDecision::AlwaysAccept,
    ] {
        let result = prefetch_permissions_from_decision(decision, prefetch_permissions());
        let entries = result
            .iter()
            .map(|(permission, policy)| (permission.as_str(), policy.to_string()))
            .collect::<Vec<_>>();

        assert_eq!(
            entries,
            vec![
                ("get_balance", "allow".to_owned()),
                ("get_assets", "allow".to_owned()),
            ]
        );
    }
}

#[test]
fn prefetch_rejection_returns_no_permission() {
    for decision in [
        UserPermissionDecision::Reject,
        UserPermissionDecision::AlwaysReject,
    ] {
        assert!(prefetch_permissions_from_decision(decision, prefetch_permissions()).is_empty());
    }
}

#[test]
fn encryption_keys_require_exactly_32_bytes_without_truncation() {
    for length in [0, 31, 33] {
        let error = encryption_key(vec![7; length]).unwrap_err();
        assert_eq!(
            error.to_string(),
            format!("Invalid XSWD relayer encryption key length: expected 32 bytes, got {length}")
        );
    }

    assert_eq!(encryption_key(vec![7; 32]).unwrap(), [7; 32]);
}

#[test]
fn encryption_modes_preserve_the_exact_valid_key() {
    assert!(convert_encryption_mode(None).unwrap().is_none());

    let aes = convert_encryption_mode(Some(EncryptionMode::Aes { key: vec![1; 32] }))
        .unwrap()
        .unwrap();
    assert!(matches!(aes, CoreEncryptionMode::AES { key } if key == [1; 32]));

    let chacha =
        convert_encryption_mode(Some(EncryptionMode::Chacha20Poly1305 { key: vec![2; 32] }))
            .unwrap()
            .unwrap();
    assert!(matches!(
        chacha,
        CoreEncryptionMode::Chacha20Poly1305 { key } if key == [2; 32]
    ));
}

#[test]
fn permission_updates_are_atomic_when_any_permission_is_unknown() {
    let mut current = IndexMap::from([
        ("get_balance".to_owned(), Permission::Ask),
        ("build_transaction".to_owned(), Permission::Reject),
    ]);
    let updates = HashMap::from([
        ("get_balance".to_owned(), PermissionPolicy::Accept),
        ("unknown".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = apply_permission_updates(&mut current, &updates).unwrap_err();

    assert_eq!(error.to_string(), "XSWD permission not found");
    assert!(matches!(current["get_balance"], Permission::Ask));
    assert!(matches!(current["build_transaction"], Permission::Reject));
}

#[test]
fn permission_updates_apply_every_supported_policy() {
    let mut current = IndexMap::from([
        ("allow".to_owned(), Permission::Ask),
        ("reject".to_owned(), Permission::Ask),
        ("ask".to_owned(), Permission::Allow),
    ]);
    let updates = HashMap::from([
        ("allow".to_owned(), PermissionPolicy::Accept),
        ("reject".to_owned(), PermissionPolicy::Reject),
        ("ask".to_owned(), PermissionPolicy::Ask),
    ]);

    apply_permission_updates(&mut current, &updates).unwrap();

    assert!(matches!(current["allow"], Permission::Allow));
    assert!(matches!(current["reject"], Permission::Reject));
    assert!(matches!(current["ask"], Permission::Ask));
}

#[tokio::test]
async fn app_permission_updates_remain_atomic_under_the_async_lock() {
    let app = app_state();
    let updates = HashMap::from([
        ("get_balance".to_owned(), PermissionPolicy::Accept),
        ("unknown".to_owned(), PermissionPolicy::Reject),
    ]);

    let error = modify_app_permissions(&app, &updates).await.unwrap_err();
    let permissions = app.get_permissions().lock().await;

    assert_eq!(error.to_string(), "XSWD permission not found");
    assert!(matches!(permissions["get_balance"], Permission::Ask));
    assert!(matches!(permissions["build_transaction"], Permission::Ask));
}

#[tokio::test]
async fn app_info_preserves_identity_metadata_and_permission_policies() {
    let app = app_state();
    {
        let mut permissions = app.get_permissions().lock().await;
        permissions.insert("get_balance".to_owned(), Permission::Allow);
        permissions.insert("build_transaction".to_owned(), Permission::Reject);
    }

    let info = create_app_info(&app).await;

    assert_eq!(info.id, "app-id");
    assert_eq!(info.name, "Test app");
    assert_eq!(info.description, "Test description");
    assert_eq!(info.url.as_deref(), Some("https://example.com"));
    assert!(!info.is_relayer);
    assert!(matches!(
        info.permissions["get_balance"],
        PermissionPolicy::Accept
    ));
    assert!(matches!(
        info.permissions["build_transaction"],
        PermissionPolicy::Reject
    ));
}

#[tokio::test]
async fn handler_routes_every_event_once_and_returns_matching_responses() {
    let calls = Arc::new(Mutex::new(Vec::<(&'static str, XswdRequestSummary)>::new()));

    let cancel_calls = Arc::clone(&calls);
    let cancel = move |summary| -> DartFnFuture<()> {
        let calls = Arc::clone(&cancel_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("cancel", summary));
        })
    };

    let application_calls = Arc::clone(&calls);
    let application = move |summary| -> DartFnFuture<UserPermissionDecision> {
        let calls = Arc::clone(&application_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("application", summary));
            UserPermissionDecision::AlwaysAccept
        })
    };

    let permission_calls = Arc::clone(&calls);
    let permission = move |summary| -> DartFnFuture<UserPermissionDecision> {
        let calls = Arc::clone(&permission_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("permission", summary));
            UserPermissionDecision::Reject
        })
    };

    let prefetch_calls = Arc::clone(&calls);
    let prefetch = move |summary| -> DartFnFuture<UserPermissionDecision> {
        let calls = Arc::clone(&prefetch_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("prefetch", summary));
            UserPermissionDecision::Accept
        })
    };

    let disconnect_calls = Arc::clone(&calls);
    let disconnect = move |summary| -> DartFnFuture<()> {
        let calls = Arc::clone(&disconnect_calls);
        Box::pin(async move {
            calls.lock().unwrap().push(("disconnect", summary));
        })
    };

    let (sender, receiver) = mpsc::unbounded_channel();
    let handler = tokio::spawn(xswd_handler(
        receiver,
        cancel,
        application,
        permission,
        prefetch,
        disconnect,
    ));
    let app = app_state();

    let (application_sender, application_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestApplication(
            Arc::clone(&app),
            application_sender,
        ))
        .unwrap();
    assert!(matches!(
        application_receiver.await.unwrap().unwrap(),
        PermissionResult::AlwaysAccept
    ));

    let (permission_sender, permission_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: Some(json!({"asset": "00"})),
            },
            permission_sender,
        ))
        .unwrap();
    assert!(matches!(
        permission_receiver.await.unwrap().unwrap(),
        PermissionResult::Reject
    ));

    let (prefetch_sender, prefetch_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::PrefetchPermissions(
            Arc::clone(&app),
            prefetch_permissions(),
            prefetch_sender,
        ))
        .unwrap();
    let prefetch_result = prefetch_receiver.await.unwrap().unwrap();
    assert_eq!(prefetch_result.len(), 2);
    assert!(prefetch_result
        .values()
        .all(|value| matches!(value, Permission::Allow)));

    let (cancel_sender, cancel_receiver) = oneshot::channel();
    sender
        .send(XSWDEvent::CancelRequest(Arc::clone(&app), cancel_sender))
        .unwrap();
    cancel_receiver.await.unwrap().unwrap();

    sender.send(XSWDEvent::AppDisconnect(app)).unwrap();
    drop(sender);
    handler.await.unwrap();

    let calls = calls.lock().unwrap();
    assert_eq!(
        calls.iter().map(|(name, _)| *name).collect::<Vec<_>>(),
        vec![
            "application",
            "permission",
            "prefetch",
            "cancel",
            "disconnect"
        ]
    );
    assert!(calls
        .iter()
        .all(|(_, summary)| summary.application_info.id == "app-id"));

    let permission_summary = &calls[1].1;
    let permission_json: serde_json::Value =
        serde_json::from_str(&permission_summary.permission_json().unwrap()).unwrap();
    assert_eq!(permission_json["method"], "get_balance");

    let prefetch_summary = &calls[2].1;
    let prefetch_json: serde_json::Value =
        serde_json::from_str(&prefetch_summary.prefetch_permissions_json().unwrap()).unwrap();
    assert_eq!(prefetch_json["permissions"][0], "get_balance");
    assert_eq!(prefetch_json["permissions"][1], "get_assets");
}

#[test]
fn dropped_permission_receivers_do_not_panic() {
    let (sender, receiver) = oneshot::channel();
    drop(receiver);

    handle_permission_decision(UserPermissionDecision::Accept, sender);
}

#[tokio::test]
async fn dropped_event_response_receivers_do_not_panic() {
    let cancel = |_| -> DartFnFuture<()> { Box::pin(async {}) };
    let application = |_| -> DartFnFuture<UserPermissionDecision> {
        Box::pin(async { UserPermissionDecision::Accept })
    };
    let permission = |_| -> DartFnFuture<UserPermissionDecision> {
        Box::pin(async { UserPermissionDecision::Reject })
    };
    let prefetch = |_| -> DartFnFuture<UserPermissionDecision> {
        Box::pin(async { UserPermissionDecision::AlwaysAccept })
    };
    let disconnect = |_| -> DartFnFuture<()> { Box::pin(async {}) };
    let app = app_state();

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::RequestApplication(Arc::clone(&app), response),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::RequestPermission(
            Arc::clone(&app),
            RpcRequest {
                jsonrpc: "2.0".to_owned(),
                id: None,
                method: "get_balance".to_owned(),
                params: None,
            },
            response,
        ),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::PrefetchPermissions(Arc::clone(&app), prefetch_permissions(), response),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;

    let (response, receiver) = oneshot::channel();
    drop(receiver);
    handle_xswd_event(
        XSWDEvent::CancelRequest(app, response),
        &cancel,
        &application,
        &permission,
        &prefetch,
        &disconnect,
    )
    .await;
}
