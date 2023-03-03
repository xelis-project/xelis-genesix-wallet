import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

class SharedPreferencesSync {
  SharedPreferencesSync(this.prefs);

  final SharedPreferences prefs;

  Future<bool> save({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    logger.info('save key: $key');
    final jsonString = jsonEncode(value);
    return prefs.setString(key, jsonString);
  }

  dynamic get({required String key}) {
    if (!prefs.containsKey(key)) {
      logger.warning('This key does not exist: "$key".');
      return null;
    }

    final jsonString = prefs.getString(key);
    if (jsonString == null) {
      logger.warning('Unable to getString for key: "$key".');
      return null;
    }
    final value = jsonDecode(jsonString);
    return value;
  }

  Future<bool> delete({required String key}) async {
    return prefs.remove(key);
  }
}
