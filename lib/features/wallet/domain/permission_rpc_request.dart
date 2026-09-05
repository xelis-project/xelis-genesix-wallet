// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_rpc_request.freezed.dart';
part 'permission_rpc_request.g.dart';

// Correlation IDs belong to XWF, which executes the original request after the
// decision. The review does not need to copy or narrow its numeric/string ID.
@Freezed(toJson: false, toStringOverride: false)
abstract class PermissionRpcRequest with _$PermissionRpcRequest {
  const PermissionRpcRequest._();

  const factory PermissionRpcRequest({
    @JsonKey(name: 'jsonrpc') required String jsonrpc,
    @JsonKey(name: 'method') required String method,
    @JsonKey(name: 'params') Map<String, dynamic>? params,
  }) = _PermissionRpcRequest;

  factory PermissionRpcRequest.fromJson(Map<String, dynamic> json) =>
      _$PermissionRpcRequestFromJson(json);

  @override
  String toString() => 'PermissionRpcRequest(<redacted>)';
}
