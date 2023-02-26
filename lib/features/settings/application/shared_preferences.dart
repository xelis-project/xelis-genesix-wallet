import 'package:shared_preferences/shared_preferences.dart';

import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

class SharedPreferencesRepository {
  const SharedPreferencesRepository();

  static const _isDarkModeKey = 'is_dark_mode';
  static const _languageSelectedKey = 'language_selected';
  static const _daemonAddressSelected = 'daemon_address_selected';
  static const _daemonAddresses = 'daemon_addresses';

  Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDarkModeKey) ?? false;
  }

  Future<String> getLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageSelectedKey) ?? AppResources.languages[0];
  }

  Future<String> getDaemonAddressSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_daemonAddressSelected) ??
        AppResources.localDaemonAddress;
  }

  Future<List<String>> getDaemonAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_daemonAddresses) ?? [];
  }

  Future<void> setIsDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, isDarkMode);
  }

  Future<void> setLanguageSelected(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageSelectedKey, language);
  }

  Future<void> setDaemonAddressSelected(String daemonAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_daemonAddressSelected, daemonAddress);
  }

  Future<void> addDaemonAddress(String daemonAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final daemonAddresses = prefs.getStringList(_daemonAddresses) ?? [];
    if (!daemonAddresses.contains(daemonAddress)) {
      daemonAddresses.add(daemonAddress);
      await prefs.setStringList(_daemonAddresses, daemonAddresses);
    }
  }

  Future<void> removeDaemonAddress(String daemonAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final daemonAddresses = prefs.getStringList(_daemonAddresses) ?? [];
    if (daemonAddresses.remove(daemonAddress)) {
      await prefs.setStringList(_daemonAddresses, daemonAddresses);
    }
  }
}
