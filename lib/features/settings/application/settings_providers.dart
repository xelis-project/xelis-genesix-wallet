import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/data/shared_preferences.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences_provider.dart';

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
class NodeAddressSelected extends _$NodeAddressSelected {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final prefsRepository = SharedPreferencesRepository(prefs);
    final currentValue = prefsRepository.getNodeAddressSelected();
    ref.listenSelf((prev, curr) {
      prefsRepository.setNodeAddressSelected(curr);
    });
    return currentValue;
  }

  void selectNodeAddress(String address) {
    state = address;
  }
}

@riverpod
class NodeAddresses extends _$NodeAddresses {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final prefsRepository = SharedPreferencesRepository(prefs);
    final currentValue = prefsRepository.getNodeAddresses();
    if (currentValue.isEmpty) {
      currentValue.addAll(AppResources.builtInNodeAddresses);
    }
    ref.listenSelf((prev, curr) {
      prefsRepository.setNodeAddresses(curr);
    });
    return currentValue;
  }

  void addNodeAddress(String address) {
    if (!state.contains(address)) {
      state = [...state, address];
    }
  }

  void removeNodeAddress(String address) {
    if (state.contains(address)) {
      state = [
        for (final element in state)
          if (element != address) element
      ];
    }
  }
}
