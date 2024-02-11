import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/theme_mode_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

// Fallback ThemeMode
const ThemeMode fallbackThemeMode = ThemeMode.system;

class ThemeModeStateRepository extends PersistentState<ThemeModeState> {
  ThemeModeStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _themeModeStorageKey = 'persistentThemeMode';

  @override
  ThemeModeState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _themeModeStorageKey);
      if (value == null) {
        return const ThemeModeState(fallbackThemeMode);
      }
      return ThemeModeState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('ThemeModeStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() async {
    return sharedPreferencesSync.delete(key: _themeModeStorageKey);
  }

  @override
  Future<bool> localSave(ThemeModeState state) async {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _themeModeStorageKey,
      value: value,
    );
  }
}
