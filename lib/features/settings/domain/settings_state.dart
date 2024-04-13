// ignore_for_file: invalid_annotation_target

import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/locale_json_converter.dart';

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
    @JsonKey(name: 'hide_balance') required bool hideBalance,
    @JsonKey(name: 'network') required Network network,
    @JsonKey(name: 'theme') required AppTheme theme,
    @LocaleJsonConverter() required Locale locale,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
