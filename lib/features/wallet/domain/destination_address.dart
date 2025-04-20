// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'destination_address.freezed.dart';

part 'destination_address.g.dart';

@freezed
abstract class DestinationAddress with _$DestinationAddress {
  const DestinationAddress._();

  const factory DestinationAddress({
    @JsonKey(name: 'address') required String address,
    @JsonKey(name: 'data') dynamic data,
  }) = _DestinationAddress;

  factory DestinationAddress.fromJson(Map<String, dynamic> json) =>
      _$DestinationAddressFromJson(json);

  bool get isIntegrated => data != null;
}
