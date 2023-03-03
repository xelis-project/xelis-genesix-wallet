import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

class SharedPreferencesRepository {
  const SharedPreferencesRepository(this.prefs);

  final SharedPreferences prefs;

  static const _darkModeKey = 'is_dark_mode';
  static const _nodeAddressSelectedKey = 'node_address_selected';
  static const _nodeAddressesKey = 'node_addresses';

  bool getIsDarkMode() {
    return prefs.getBool(_darkModeKey) ?? false;
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

  Future<void> setNodeAddressSelected(String nodeAddress) async {
    logger.info('set nodeAddressSelected preference: $nodeAddress');
    await prefs.setString(_nodeAddressSelectedKey, nodeAddress);
  }

  Future<void> setNodeAddresses(List<String> addresses) async {
    logger.info('set NodeAddresses preference: $addresses');
    await prefs.setStringList(_nodeAddressesKey, addresses);
  }
}
