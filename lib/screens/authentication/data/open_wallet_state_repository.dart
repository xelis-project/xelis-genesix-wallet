import 'package:xelis_mobile_wallet/screens/authentication/domain/open_wallet_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class OpenWalletStateRepository extends PersistentState<OpenWalletState> {
  OpenWalletStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _openWalletsStorageKey = 'persistentOpenWallets';

  @override
  OpenWalletState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _openWalletsStorageKey);
      if (value == null) {
        return const OpenWalletState();
      }
      return OpenWalletState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('NodeAddressesStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() {
    return sharedPreferencesSync.delete(key: _openWalletsStorageKey);
  }

  @override
  Future<bool> localSave(OpenWalletState state) {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _openWalletsStorageKey,
      value: value,
    );
  }
}
