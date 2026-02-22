import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageRepository {
  final String _namespace = 'genesix_secure_storage';
  late FlutterSecureStorage storage;

  SecureStorageRepository() {
    storage = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
      mOptions: _getMacOsOptions(),
    );
  }

  IOSOptions _getIOSOptions() => IOSOptions(accountName: _namespace);

  AndroidOptions _getAndroidOptions() => AndroidOptions(
    sharedPreferencesName: _namespace,
    preferencesKeyPrefix: 'genesix',
  );

  MacOsOptions _getMacOsOptions() => MacOsOptions(accountName: _namespace);

  Future<void> write({required String key, required String value}) async {
    await storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await storage.deleteAll();
  }

  Future<bool> containsKey({required String key}) async {
    return await storage.containsKey(key: key);
  }
}
