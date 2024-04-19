// ignore_for_file: invalid_annotation_target

import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
import 'package:genesix/features/settings/domain/locale_json_converter.dart';

part 'settings_state.freezed.dart';

part 'settings_state.g.dart';

enum AppTheme {
  light,
  dark,
  xelis,
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @JsonKey(name: 'hide_balance') @Default(false) bool hideBalance,
    @JsonKey(name: 'hide_extra_data') @Default(false) bool hideExtraData,
    @JsonKey(name: 'hide_zero_transfer') @Default(false) bool hideZeroTransfer,
    @JsonKey(name: 'network') @Default(Network.mainnet) Network network,
    @JsonKey(name: 'theme') @Default(AppTheme.xelis) AppTheme theme,
    @LocaleJsonConverter() required Locale locale,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
