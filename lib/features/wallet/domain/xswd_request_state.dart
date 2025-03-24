import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';

part 'xswd_request_state.freezed.dart';

@freezed
abstract class XswdRequestState with _$XswdRequestState {
  const factory XswdRequestState({
    XswdRequestSummary? xswdEventSummary,
    Timer? snackBarTimer,
    Completer<UserPermissionDecision>? decision,
    PermissionRpcRequest? permissionRpcRequest,
    required String message,
    required bool snackBarVisible,
  }) = _XswdRequestState;
}
