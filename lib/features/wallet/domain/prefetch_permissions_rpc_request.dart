// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'prefetch_permissions_rpc_request.freezed.dart';
part 'prefetch_permissions_rpc_request.g.dart';

@freezed
abstract class PrefetchPermissionsRequest with _$PrefetchPermissionsRequest {
  const factory PrefetchPermissionsRequest({
    String? reason,
    required List<String> permissions,
  }) = _PrefetchPermissionsRequest;

  factory PrefetchPermissionsRequest.fromJson(Map<String, dynamic> json) =>
      _$PrefetchPermissionsRequestFromJson(json);
}
