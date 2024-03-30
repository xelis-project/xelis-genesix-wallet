import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/screens/settings/data/network_state_repository.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

part 'network_state_provider.g.dart';

@riverpod
class Network extends _$Network {
  @override
  NetworkState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final networkStateRepository =
        NetworkStateRepository(SharedPreferencesSync(prefs));
    return networkStateRepository.fromStorage();
  }

  void setNetwork(NetworkType networkType) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkStateRepository =
        NetworkStateRepository(SharedPreferencesSync(prefs));
    state = state.copyWith(networkType: networkType);
    networkStateRepository.localSave(state);
  }
}
