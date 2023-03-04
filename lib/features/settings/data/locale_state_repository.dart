import 'dart:ui';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xelis_mobile_wallet/features/settings/data/persistent_state.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/locale_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences_sync.dart';

// Fallback Locale
const Locale fallbackLocale = Locale('en');

class LocaleStateRepository extends PersistentState<LocaleState> {
  LocaleStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _localStorageKey = 'persistentLocale';

  @override
  LocaleState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _localStorageKey);
      if (value == null) {
        if (AppLocalizations.supportedLocales
            .contains(Locale(window.locale.languageCode))) {
          return LocaleState(Locale(window.locale.languageCode));
        } else {
          return const LocaleState(fallbackLocale);
        }
      } else {
        return LocaleState.fromJson(value as Map<String, dynamic>);
      }
    } catch (e) {
      logger.severe(e);
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() async {
    return sharedPreferencesSync.delete(key: _localStorageKey);
  }

  @override
  Future<bool> localSave(LocaleState state) async {
    if (AppLocalizations.supportedLocales.contains(state.locale)) {
      final value = state.toJson();
      return sharedPreferencesSync.save(
        key: _localStorageKey,
        value: value,
      );
    } else {
      return false;
    }
  }
}
