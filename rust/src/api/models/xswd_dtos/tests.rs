use super::*;

fn app_info() -> AppInfo {
    AppInfo {
        id: "app-id".to_owned(),
        name: "Test app".to_owned(),
        description: "Test description".to_owned(),
        url: Some("https://example.com".to_owned()),
        permissions: HashMap::new(),
        is_relayer: false,
    }
}

#[test]
fn request_type_helpers_identify_each_event_exclusively() {
    let cases = [
        (
            XswdRequestType::Application,
            [false, true, false, false, false],
        ),
        (
            XswdRequestType::Permission("{\"method\":\"get_balance\"}".to_owned()),
            [false, false, true, false, false],
        ),
        (
            XswdRequestType::PrefetchPermissions("{\"permissions\":[\"get_balance\"]}".to_owned()),
            [false, false, false, true, false],
        ),
        (
            XswdRequestType::CancelRequest,
            [true, false, false, false, false],
        ),
        (
            XswdRequestType::AppDisconnect,
            [false, false, false, false, true],
        ),
    ];

    for (event_type, expected) in cases {
        let summary = XswdRequestSummary::new(event_type, app_info());
        assert_eq!(
            [
                summary.is_cancel_request(),
                summary.is_application_request(),
                summary.is_permission_request(),
                summary.is_prefetch_permissions_request(),
                summary.is_app_disconnect(),
            ],
            expected
        );
    }
}

#[test]
fn request_json_is_exposed_only_for_its_matching_event() {
    let permission_json = "{\"method\":\"get_balance\"}".to_owned();
    let permission = XswdRequestSummary::new(
        XswdRequestType::Permission(permission_json.clone()),
        app_info(),
    );
    assert_eq!(permission.permission_json(), Some(permission_json));
    assert_eq!(permission.prefetch_permissions_json(), None);

    let prefetch_json = "{\"permissions\":[\"get_balance\"]}".to_owned();
    let prefetch = XswdRequestSummary::new(
        XswdRequestType::PrefetchPermissions(prefetch_json.clone()),
        app_info(),
    );
    assert_eq!(prefetch.permission_json(), None);
    assert_eq!(prefetch.prefetch_permissions_json(), Some(prefetch_json));

    let application = XswdRequestSummary::new(XswdRequestType::Application, app_info());
    assert_eq!(application.permission_json(), None);
    assert_eq!(application.prefetch_permissions_json(), None);
}
