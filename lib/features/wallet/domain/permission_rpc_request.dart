// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_rpc_request.freezed.dart';
part 'permission_rpc_request.g.dart';

@freezed
abstract class PermissionRpcRequest with _$PermissionRpcRequest {
  const factory PermissionRpcRequest({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'jsonrpc') required String jsonrpc,
    @JsonKey(name: 'method') required String method,
    @JsonKey(name: 'params') required Map<String, dynamic> params,
  }) = _PermissionRpcRequest;

  factory PermissionRpcRequest.fromJson(Map<String, dynamic> json) =>
      _$PermissionRpcRequestFromJson(json);
}
