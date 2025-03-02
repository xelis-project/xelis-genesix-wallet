// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_address.freezed.dart';

part 'wallet_address.g.dart';

@freezed
abstract class WalletAddress with _$WalletAddress {
  const WalletAddress._();

  const factory WalletAddress({
    @JsonKey(name: 'address') required String address,
    @JsonKey(name: 'data') dynamic data,
  }) = _WalletAddress;

  factory WalletAddress.fromJson(Map<String, dynamic> json) =>
      _$WalletAddressFromJson(json);

  bool get isIntegrated => data != null;
}
