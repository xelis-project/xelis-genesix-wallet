import 'dart:ui';

import 'package:genesix/rust_bridge/api/network.dart';
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
    final settingsStateRepository =
        SettingsStateRepository(GenesixSharedPreferences(prefs));
    return settingsStateRepository.fromStorage();
  }

  void setState(SettingsState state) {
    final prefs = ref.read(sharedPreferencesProvider);
    final settingsStateRepository =
        SettingsStateRepository(GenesixSharedPreferences(prefs));
    settingsStateRepository.localSave(state);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    setState(state);
  }

  void setNetwork(Network network) {
    state = state.copyWith(network: network);
    setState(state);
  }

  void setTheme(AppTheme theme) {
    state = state.copyWith(theme: theme);
    setState(state);
  }

  void setHideBalance(bool hideBalance) {
    state = state.copyWith(hideBalance: hideBalance);
    setState(state);
  }

  void setHideExtraData(bool hideExtraData) {
    state = state.copyWith(hideExtraData: hideExtraData);
    setState(state);
  }

  void setHideZeroTransfer(bool hideZeroTransfer) {
    state = state.copyWith(hideZeroTransfer: hideZeroTransfer);
    setState(state);
  }

  void setUnlockBurn(bool unlockBurn) {
    state = state.copyWith(unlockBurn: unlockBurn);
    setState(state);
  }

  void setActivateLogger(bool activateLogger) {
    state = state.copyWith(activateLogger: activateLogger);
    setState(state);
  }

  void setShowBalanceUSDT(bool showBalanceUSDT) {
    state = state.copyWith(showBalanceUSDT: showBalanceUSDT);
    setState(state);
  }
}
