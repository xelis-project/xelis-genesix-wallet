import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/locale_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

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
        final languageCode =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        if (AppLocalizations.supportedLocales.contains(Locale(languageCode))) {
          return LocaleState(Locale(languageCode));
        } else {
          return const LocaleState(fallbackLocale);
        }
      } else {
        return LocaleState.fromJson(value as Map<String, dynamic>);
      }
    } catch (e) {
      logger.severe('LocalStateRepository: $e');
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
