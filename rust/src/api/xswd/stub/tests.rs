use super::*;

#[test]
fn unavailable_operations_fail_explicitly() {
    let error = xswd_unavailable::<()>().unwrap_err();

    assert_eq!(
        error.to_string(),
        "XSWD support is not enabled in this build"
    );
}

#[test]
fn stub_event_names_cover_every_contract_variant() {
    let cases = [
        (XSWDEvent::CancelRequest, "CancelRequest"),
        (XSWDEvent::RequestApplication, "RequestApplication"),
        (XSWDEvent::RequestPermission, "RequestPermission"),
        (XSWDEvent::PrefetchPermissions, "PrefetchPermissions"),
        (XSWDEvent::AppDisconnect, "AppDisconnect"),
    ];

    for (event, expected) in cases {
        assert_eq!(xswd_event_name(&event), expected);
    }
}

#[tokio::test]
async fn stub_application_info_is_explicitly_empty() {
    let info = create_app_info(&AppState).await;

    assert!(info.id.is_empty());
    assert!(info.name.is_empty());
    assert!(info.description.is_empty());
    assert!(info.url.is_none());
    assert!(info.permissions.is_empty());
    assert!(!info.is_relayer);
}

#[tokio::test]
async fn stub_permission_decisions_return_the_matching_result() {
    let cases = [
        (UserPermissionDecision::Accept, "accept"),
        (UserPermissionDecision::Reject, "reject"),
        (UserPermissionDecision::AlwaysAccept, "always_accept"),
        (UserPermissionDecision::AlwaysReject, "always_reject"),
    ];

    for (decision, expected) in cases {
        let (sender, receiver) = xelis_common::tokio::sync::oneshot::channel();
        handle_permission_decision(decision, sender);
        let result = receiver.await.unwrap().unwrap();
        let actual = match result {
            PermissionResult::Accept => "accept",
            PermissionResult::Reject => "reject",
            PermissionResult::AlwaysAccept => "always_accept",
            PermissionResult::AlwaysReject => "always_reject",
        };

        assert_eq!(actual, expected);
    }
}
