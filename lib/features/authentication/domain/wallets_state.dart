// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/settings/domain/last_wallets_used.dart';

part 'wallets_state.freezed.dart';

part 'wallets_state.g.dart';

@freezed
abstract class WalletsState with _$WalletsState {
  const factory WalletsState({
    @JsonKey(name: 'wallets') @Default({}) Map<String, String> wallets,
    @JsonKey(name: 'last_wallets_used')
    required LastWalletsUsed lastWalletsUsed,
  }) = _WalletsState;

  factory WalletsState.fromJson(Map<String, dynamic> json) =>
      _$WalletsStateFromJson(json);
}
