import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

typedef CancelCb = Future<void> Function(XswdRequestSummary request);
typedef DecisionCb =
    Future<UserPermissionDecision> Function(XswdRequestSummary request);

class XswdCallbacks {
  const XswdCallbacks({
    required this.cancelRequestCallback,
    required this.requestApplicationCallback,
    required this.requestPermissionCallback,
    required this.requestPrefetchPermissionsCallback,
    required this.appDisconnectCallback,
  });

  final CancelCb cancelRequestCallback;
  final DecisionCb requestApplicationCallback;
  final DecisionCb requestPermissionCallback;
  final DecisionCb requestPrefetchPermissionsCallback;
  final CancelCb appDisconnectCallback;
}
