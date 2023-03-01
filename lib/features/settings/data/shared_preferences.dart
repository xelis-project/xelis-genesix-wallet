import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

class SharedPreferencesRepository {
  const SharedPreferencesRepository(this.prefs);

  final SharedPreferences prefs;

  static const _darkModeKey = 'is_dark_mode';
  static const _languageSelectedKey = 'language_selected';
  static const _nodeAddressSelectedKey = 'node_address_selected';
  static const _nodeAddressesKey = 'node_addresses';

  bool getIsDarkMode() {
    return prefs.getBool(_darkModeKey) ?? false;
  }

  String getLanguageSelected() {
    return prefs.getString(_languageSelectedKey) ?? AppResources.languages[0];
  }

  String getNodeAddressSelected() {
    return prefs.getString(_nodeAddressSelectedKey) ??
        AppResources.localNodeAddress;
  }

  List<String> getNodeAddresses() {
    return prefs.getStringList(_nodeAddressesKey) ?? [];
  }

  Future<void> setIsDarkMode(bool isDarkMode) async {
    logger.info('set darkMode preference: $isDarkMode');
    await prefs.setBool(_darkModeKey, isDarkMode);
  }

  Future<void> setLanguageSelected(String language) async {
    logger.info('set Selected Language preference: $language');
    await prefs.setString(_languageSelectedKey, language);
  }

  Future<void> setNodeAddressSelected(String nodeAddress) async {
    logger.info('set nodeAddressSelected preference: $nodeAddress');
    await prefs.setString(_nodeAddressSelectedKey, nodeAddress);
  }

  Future<void> setNodeAddresses(List<String> addresses) async {
    logger.info('set NodeAddresses preference: $addresses');
    await prefs.setStringList(_nodeAddressesKey, addresses);
  }
}
