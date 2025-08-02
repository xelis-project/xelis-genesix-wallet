// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'last_wallets_used.g.dart';

part 'last_wallets_used.freezed.dart';

@freezed
abstract class LastWalletsUsed with _$LastWalletsUsed {
  const factory LastWalletsUsed({
    @JsonKey(name: 'mainnet') String? mainnet,
    @JsonKey(name: 'testnet') String? testnet,
    @JsonKey(name: 'stagenet') String? stagenet,
    @JsonKey(name: 'devnet') String? devnet,
  }) = _LastWalletsUsed;

  factory LastWalletsUsed.fromJson(Map<String, dynamic> json) =>
      _$LastWalletsUsedFromJson(json);
}
