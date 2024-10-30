// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';

part 'address.g.dart';

@freezed
class Address with _$Address {
  const Address._();

  const factory Address({
    @JsonKey(name: 'address') required String address,
    @JsonKey(name: 'data') dynamic data,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  bool get isIntegrated => data != null;
}
