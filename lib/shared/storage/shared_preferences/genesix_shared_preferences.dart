import 'dart:convert';

import 'package:genesix/features/settings/data/settings_state_repository.dart';
import 'package:genesix/features/wallet/data/network_nodes_state_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genesix/features/logger/logger.dart';

class GenesixSharedPreferences {
  GenesixSharedPreferences(this.prefs);

  final SharedPreferencesWithCache prefs;

  static Future<SharedPreferencesWithCache> setUp() async {
    return SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {
        SettingsStateRepository.storageKey,
        NetworkNodesStateRepository.storageKey
      }),
    );
  }

  Future<void> save({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    talker.info('save key: $key');
    final jsonString = jsonEncode(value);
    await prefs.setString(key, jsonString);
  }

  dynamic get({required String key}) {
    if (!prefs.containsKey(key)) {
      talker.warning('This key does not exist: "$key".');
      return null;
    }

    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      talker.warning('Unable to getString for key: "$key".');
      return null;
    }
    final value = jsonDecode(jsonString);
    return value;
  }

  Future<void> delete({required String key}) async {
    talker.info('remove key: $key');
    await prefs.remove(key);
  }
}
