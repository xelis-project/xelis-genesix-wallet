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
    Object? token,
    @Default(false) bool pending,
    PermissionRpcRequest? permissionRpcRequest,
    XswdPermissionReview? permissionReview,
    PrefetchPermissionsRequest? prefetchPermissionsRequest,
    @Default('') String message,
    @Default(false) bool suppressXswdToast,
  }) = _XswdRequestState;
}
