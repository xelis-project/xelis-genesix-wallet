// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_address.freezed.dart';

part 'node_address.g.dart';

@freezed
abstract class NodeAddress with _$NodeAddress {
  const factory NodeAddress({
    @JsonKey(name: 'name') @Default('') String name,
    @JsonKey(name: 'url') @Default('') String url,
  }) = _NodeAddress;

  factory NodeAddress.fromJson(Map<String, dynamic> json) =>
      _$NodeAddressFromJson(json);
}
