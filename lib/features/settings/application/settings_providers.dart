import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/application/languages.dart';
import 'package:xelis_mobile_wallet/features/settings/data/shared_preferences.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

part 'settings_providers.g.dart';

@riverpod
class DarkMode extends _$DarkMode {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final prefsRepository = SharedPreferencesRepository(prefs);
    final currentValue = prefsRepository.getIsDarkMode();
    ref.listenSelf((prev, curr) {
      prefsRepository.setIsDarkMode(curr);
    });
    return currentValue;
  }

  void switchState() {
    state = !state;
  }
}

/*class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier(super.state);

  void switchState() {
    state = !state;
  }
}

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final prefsRepository = SharedPreferencesRepository(prefs);
  final currentValue = prefsRepository.getIsDarkMode();
  ref.listenSelf((prev, curr) {
    prefsRepository.setIsDarkMode(curr);
  });
  return DarkModeNotifier(currentValue);
});*/

@riverpod
class LanguageSelected extends _$LanguageSelected {
  @override
  Languages build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final prefsRepository = SharedPreferencesRepository(prefs);
    final currentValue = prefsRepository.getLanguageSelected();
    ref.listenSelf((prev, curr) {
      prefsRepository.setLanguageSelected(curr.name);
    });
    return getLanguage(currentValue);
  }

  void selectLanguage(Languages language) {
    state = language;
  }
}

/*class SelectedLanguageNotifier extends StateNotifier<Languages> {
  SelectedLanguageNotifier(super.state);

  void selectLanguage(Languages language) {
    state = language;
  }
}

final selectedLanguageProvider =
    StateNotifierProvider<SelectedLanguageNotifier, Languages>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final prefsRepository = SharedPreferencesRepository(prefs);
  final currentValue = prefsRepository.getLanguageSelected();
  ref.listenSelf((prev, curr) {
    prefsRepository.setLanguageSelected(curr.name);
  });
  return SelectedLanguageNotifier(getLanguage(currentValue));
});*/

@riverpod
class DaemonAddressSelected extends _$DaemonAddressSelected {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final prefsRepository = SharedPreferencesRepository(prefs);
    final currentValue = prefsRepository.getDaemonAddressSelected();
    ref.listenSelf((prev, curr) {
      prefsRepository.setDaemonAddressSelected(curr);
    });
    return currentValue;
  }

  void selectDaemonAddress(String address) {
    state = address;
  }
}

@riverpod
class DaemonAddresses extends _$DaemonAddresses {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final prefsRepository = SharedPreferencesRepository(prefs);
    final currentValue = prefsRepository.getDaemonAddresses();
    if (currentValue.isEmpty) {
      currentValue.addAll(AppResources.builtInDaemonAddresses);
    }
    ref.listenSelf((prev, curr) {
      prefsRepository.setDaemonAddresses(curr);
    });
    return currentValue;
  }

  void addDaemonAddress(String address) {
    if (!state.contains(address)) {
      state = [...state, address];
    }
  }

  void removeDaemonAddress(String address) {
    if (state.contains(address)) {
      state = [
        for (final element in state)
          if (element != address) element
      ];
    }
  }
}
