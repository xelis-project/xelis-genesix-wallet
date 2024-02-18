// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance_mode_state.freezed.dart';

part 'balance_mode_state.g.dart';

@freezed
class BalanceModeState with _$BalanceModeState {
  const factory BalanceModeState({
    @JsonKey(name: 'hide') required bool hide,
  }) = _BalanceModeState;

  factory BalanceModeState.fromJson(Map<String, dynamic> json) =>
      _$BalanceModeStateFromJson(json);
}
