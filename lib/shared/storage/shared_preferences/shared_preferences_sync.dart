import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:genesix/features/logger/logger.dart';

class SharedPreferencesSync {
  SharedPreferencesSync(this.prefs);

  final SharedPreferences prefs;

  Future<bool> save({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    talker.info('save key: $key');
    final jsonString = jsonEncode(value);
    return prefs.setString(key, jsonString);
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

  Future<bool> delete({required String key}) async {
    talker.info('remove key: $key');
    return prefs.remove(key);
  }
}
