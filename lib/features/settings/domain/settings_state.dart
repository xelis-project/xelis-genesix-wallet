// ignore_for_file: invalid_annotation_target

import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/features/settings/domain/locale_json_converter.dart';

part 'settings_state.freezed.dart';

part 'settings_state.g.dart';

enum AppTheme { light, dark, xelis }

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @JsonKey(name: 'hide_balance') @Default(false) bool hideBalance,
    @JsonKey(name: 'history_filter_state')
    @Default(HistoryFilterState())
    HistoryFilterState historyFilterState,
    @JsonKey(name: 'unlock_burn') @Default(false) bool unlockBurn,
    @JsonKey(name: 'show_balance_usdt') @Default(false) bool showBalanceUSDT,
    @JsonKey(name: 'enable_xswd') @Default(false) bool enableXswd,
    @JsonKey(name: 'activate_biometric_auth')
    @Default(false)
    bool activateBiometricAuth,
    @JsonKey(name: 'network') @Default(Network.mainnet) Network network,
    @JsonKey(name: 'theme') @Default(AppTheme.xelis) AppTheme theme,
    @LocaleJsonConverter() required Locale locale,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
