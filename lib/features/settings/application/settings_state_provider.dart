import 'dart:ui';

import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/settings/data/settings_state_repository.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';

part 'settings_state_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final settingsStateRepository = SettingsStateRepository(
      GenesixSharedPreferences(prefs),
    );
    return settingsStateRepository.fromStorage();
  }

  void _setState(SettingsState state) {
    final prefs = ref.read(sharedPreferencesProvider);
    final settingsStateRepository = SettingsStateRepository(
      GenesixSharedPreferences(prefs),
    );
    settingsStateRepository.localSave(state);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _setState(state);
  }

  void setNetwork(Network network) {
    state = state.copyWith(network: network);
    _setState(state);
  }

  void setTheme(AppTheme theme) {
    state = state.copyWith(theme: theme);
    _setState(state);
  }

  void setHideBalance(bool hideBalance) {
    state = state.copyWith(hideBalance: hideBalance);
    _setState(state);
  }

  void setUnlockBurn(bool unlockBurn) {
    state = state.copyWith(unlockBurn: unlockBurn);
    _setState(state);
  }

  void setShowBalanceUSDT(bool showBalanceUSDT) {
    state = state.copyWith(showBalanceUSDT: showBalanceUSDT);
    _setState(state);
  }

  void setActivateBiometricAuth(bool activateBiometricAuth) {
    state = state.copyWith(activateBiometricAuth: activateBiometricAuth);
    _setState(state);
  }

  void setEnableXswd(bool enableXswd) {
    state = state.copyWith(enableXswd: enableXswd);
    _setState(state);
  }

  void setHistoryFilterState(HistoryFilterState historyFilterState) {
    state = state.copyWith(historyFilterState: historyFilterState);
    _setState(state);
  }
}
