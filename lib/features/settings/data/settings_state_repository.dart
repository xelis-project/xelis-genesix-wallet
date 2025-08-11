import 'package:flutter/material.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/storage/persistent_state.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

class SettingsStateRepository extends PersistentState<SettingsState> {
  SettingsStateRepository(this.genesixSharedPreferences);

  final GenesixSharedPreferences genesixSharedPreferences;
  static const storageKey = 'settings';

  @override
  SettingsState fromStorage() {
    var locale = const Locale('en');
    try {
      final value =
          genesixSharedPreferences.get(key: storageKey)
              as Map<String, dynamic>?;
      if (value == null) {
        // check user system language and apply if available
        final languageCode =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        if (AppLocalizations.supportedLocales.contains(Locale(languageCode))) {
          locale = Locale(languageCode);
        }

        return SettingsState(locale: locale);
      }

      return SettingsState.fromJson(value);
    } catch (e) {
      talker.critical('SettingsStateRepository: $e');
      return SettingsState(locale: locale);
    }
  }

  @override
  Future<void> localDelete() async {
    await genesixSharedPreferences.delete(key: storageKey);
  }

  @override
  Future<void> localSave(SettingsState state) async {
    final value = state.toJson();
    await genesixSharedPreferences.save(key: storageKey, value: value);
  }
}
