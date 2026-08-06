import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'xswd_request_state.freezed.dart';

@freezed
abstract class XswdRequestState with _$XswdRequestState {
  const factory XswdRequestState({
    XelisXswdRequest? xswdEventSummary,
    Timer? snackBarTimer,
    Completer<XelisXswdDecision>? decision,
    PermissionRpcRequest? permissionRpcRequest,
    XswdPermissionReview? permissionReview,
    PrefetchPermissionsRequest? prefetchPermissionsRequest,
    required String message,
    required bool snackBarVisible,
    @Default(false) bool suppressXswdToast,
  }) = _XswdRequestState;
}
