import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

class SharedPreferencesRepository {
  const SharedPreferencesRepository(this.prefs);

  final SharedPreferences prefs;

  static const _isDarkModeKey = 'is_dark_mode';
  static const _languageSelectedKey = 'language_selected';
  static const _daemonAddressSelected = 'daemon_address_selected';
  static const _daemonAddresses = 'daemon_addresses';

  bool getIsDarkMode() {
    return prefs.getBool(_isDarkModeKey) ?? false;
  }

  String getLanguageSelected() {
    return prefs.getString(_languageSelectedKey) ?? AppResources.languages[0];
  }

  String getDaemonAddressSelected() {
    return prefs.getString(_daemonAddressSelected) ??
        AppResources.localDaemonAddress;
  }

  List<String> getDaemonAddresses() {
    return prefs.getStringList(_daemonAddresses) ?? [];
  }

  Future<void> setIsDarkMode(bool isDarkMode) async {
    logger.info('set darkMode preference: $isDarkMode');
    await prefs.setBool(_isDarkModeKey, isDarkMode);
  }

  Future<void> setLanguageSelected(String language) async {
    logger.info('set Selected Language preference: $language');
    await prefs.setString(_languageSelectedKey, language);
  }

  Future<void> setDaemonAddressSelected(String daemonAddress) async {
    logger.info('set daemonAddressSelected preference: $daemonAddress');
    await prefs.setString(_daemonAddressSelected, daemonAddress);
  }

  Future<void> setDaemonAddresses(List<String> addresses) async {
    logger.info('set DaemonAddresses preference: $addresses');
    await prefs.setStringList(_daemonAddresses, addresses);
  }

/*  Future<void> addDaemonAddress(String daemonAddress) async {
    logger.info('add new daemon address');
    final daemonAddresses = prefs.getStringList(_daemonAddresses) ?? [];
    if (!daemonAddresses.contains(daemonAddress)) {
      daemonAddresses.add(daemonAddress);
      await prefs.setStringList(_daemonAddresses, daemonAddresses);
    }
  }

  Future<void> removeDaemonAddress(String daemonAddress) async {
    logger.info('remove a daemon address');
    final daemonAddresses = prefs.getStringList(_daemonAddresses) ?? [];
    if (daemonAddresses.remove(daemonAddress)) {
      await prefs.setStringList(_daemonAddresses, daemonAddresses);
    }
  }*/
}
