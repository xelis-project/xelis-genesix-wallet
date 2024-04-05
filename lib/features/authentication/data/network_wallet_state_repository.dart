import 'package:xelis_mobile_wallet/features/authentication/domain/network_wallet_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class NetworkWalletStateRepository extends PersistentState<NetworkWalletState> {
  NetworkWalletStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _storageKey = 'network_wallet';

  @override
  NetworkWalletState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _storageKey);
      if (value == null) {
        return const NetworkWalletState();
      }
      return NetworkWalletState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('NetworkWalletStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() {
    return sharedPreferencesSync.delete(key: _storageKey);
  }

  @override
  Future<bool> localSave(NetworkWalletState state) {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _storageKey,
      value: value,
    );
  }
}
