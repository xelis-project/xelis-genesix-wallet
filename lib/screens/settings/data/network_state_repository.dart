import 'package:xelis_mobile_wallet/screens/settings/domain/network_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class NetworkStateRepository extends PersistentState<NetworkState> {
  NetworkStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _networkStorageKey = 'persistentNetwork';

  @override
  NetworkState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _networkStorageKey);
      if (value == null) {
        return const NetworkState(NetworkType.mainnet);
      }
      return NetworkState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('NetworkStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() async {
    return sharedPreferencesSync.delete(key: _networkStorageKey);
  }

  @override
  Future<bool> localSave(NetworkState state) async {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _networkStorageKey,
      value: value,
    );
  }
}
