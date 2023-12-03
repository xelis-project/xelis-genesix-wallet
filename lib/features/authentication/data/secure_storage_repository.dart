import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:xelis_mobile_wallet/shared/logger.dart';

class SecureStorageRepository {
  SecureStorageRepository._();

  static const _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);

  static const _iosOptions =
      IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  static const _secureStorage =
      FlutterSecureStorage(iOptions: _iosOptions, aOptions: _androidOptions);

  static Future<void> save({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final jsonString = jsonEncode(value);
    logger.info('saving value in secure storage (key: $key).');
    await _secureStorage.write(key: key, value: jsonString);
  }

  static Future<dynamic> get({required String key}) async {
    final jsonString = await _secureStorage.read(key: key);
    if (jsonString == null) {
      logger.warning(
        'Unable to find this value in secure storage (key: "$key").',
      );
      return null;
    }
    final value = jsonDecode(jsonString);
    return value;
  }

  static Future<Map<String, String>> getAll() async {
    return _secureStorage.readAll();
  }

  static Future<bool> contain({required String key}) async =>
      _secureStorage.containsKey(key: key);

  static Future<void> delete(String key) async {
    logger.info('deleting value in secure storage (key: $key).');
    await _secureStorage.delete(key: key);
  }

  static Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
}
