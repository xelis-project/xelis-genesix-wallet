import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/application/shared_preferences.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/settings.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
class AsyncSettings extends _$AsyncSettings {
  Future<Settings> _fetchSettings() async {
    const prefsRepository = SharedPreferencesRepository();
    final isDarkMode = await prefsRepository.getIsDarkMode();
    final languageSelected = await prefsRepository.getLanguageSelected();
    final daemonAddressSelected =
        await prefsRepository.getDaemonAddressSelected();
    final daemonAddresses = AppResources.builtInDaemonAddresses;
    final registeredDaemonAddresses =
        await prefsRepository.getDaemonAddresses();
    if (registeredDaemonAddresses.isNotEmpty) {
      daemonAddresses.addAll(registeredDaemonAddresses);
    }
    return Settings(
      isDarkMode: isDarkMode,
      languageSelected: languageSelected,
      daemonAddressSelected: daemonAddressSelected,
      daemonAddresses: daemonAddresses,
    );
  }

  @override
  FutureOr<Settings> build() async {
    return _fetchSettings();
  }

  Future<void> selectDarkMode() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await const SharedPreferencesRepository().setIsDarkMode(true);
      return _fetchSettings();
    });
  }

  Future<void> selectLightMode() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await const SharedPreferencesRepository().setIsDarkMode(false);
      return _fetchSettings();
    });
  }

  Future<void> selectLanguage(String language) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await const SharedPreferencesRepository().setLanguageSelected(language);
      return _fetchSettings();
    });
  }

  Future<void> selectDaemonAddress(String daemonAddress) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await const SharedPreferencesRepository()
          .setDaemonAddressSelected(daemonAddress);
      return _fetchSettings();
    });
  }

  Future<void> addDaemonAddress(String daemonAddress) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await const SharedPreferencesRepository().addDaemonAddress(daemonAddress);
      return _fetchSettings();
    });
  }

  Future<void> removeDaemonAddress(String daemonAddress) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await const SharedPreferencesRepository()
          .removeDaemonAddress(daemonAddress);
      return _fetchSettings();
    });
  }

/*void selectDarkMode() {
    state = state.copyWith(isDarkMode: true);
  }

  void selectLightMode() {
    state = state.copyWith(isDarkMode: false);
  }

  void changeLanguage(Languages language) {
    state = state.copyWith(languages: language);
  }

  void selectDaemonAddress(String address) {
    if (state.daemonAddresses.contains(address)) {
      state = state.copyWith(daemonAddressSelected: address);
    }
  }

  void addDaemonAddress(String address) {
    final addresses = [...state.daemonAddresses, address];
    state = state.copyWith(daemonAddresses: addresses);
  }

  void removeDaemonAddress(String address) {
    final addresses = [
      for (final addr in state.daemonAddresses)
        if (address != addr) addr
    ];
    state = state.copyWith(daemonAddresses: addresses);
  }*/
}

// final settingsProvider =
//     StateNotifierProvider.family<SettingsNotifier, Settings, Settings>(
//         (ref, userSettings) {
//   return SettingsNotifier(userSettings);
// });
