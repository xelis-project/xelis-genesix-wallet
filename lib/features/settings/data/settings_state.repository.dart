import 'package:flutter/material.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/storage/persistent_state.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_sync.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsStateRepository extends PersistentState<SettingsState> {
  SettingsStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _storageKey = 'settings';

  @override
  SettingsState fromStorage() {
    try {
      final value =
          sharedPreferencesSync.get(key: _storageKey) as Map<String, dynamic>?;
      if (value == null) {
        var locale = const Locale('en');

        // check user system language and apply if available
        final languageCode =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        if (AppLocalizations.supportedLocales.contains(Locale(languageCode))) {
          locale = Locale(languageCode);
        }

        return SettingsState(
          hideBalance: false,
          locale: locale,
          network: Network.mainnet,
          theme: AppTheme.xelis,
        );
      }

      return SettingsState.fromJson(value);
    } catch (e) {
      logger.severe('SettingsStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() async {
    return sharedPreferencesSync.delete(key: _storageKey);
  }

  @override
  Future<bool> localSave(SettingsState state) async {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _storageKey,
      value: value,
    );
  }
}
