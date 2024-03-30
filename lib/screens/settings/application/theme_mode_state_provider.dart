import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/screens/settings/data/theme_mode_state_repository.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/theme_mode_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

part 'theme_mode_state_provider.g.dart';

@riverpod
class UserThemeMode extends _$UserThemeMode {
  @override
  ThemeModeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeModeStateRepository =
        ThemeModeStateRepository(SharedPreferencesSync(prefs));
    return themeModeStateRepository.fromStorage();
  }

  void setThemeMode(ThemeMode themeMode) {
    final prefs = ref.read(sharedPreferencesProvider);
    final themeModeStateRepository =
        ThemeModeStateRepository(SharedPreferencesSync(prefs));
    state = state.copyWith(themeMode: themeMode);
    themeModeStateRepository.localSave(state);
  }
}
