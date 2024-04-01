import 'package:xelis_mobile_wallet/screens/authentication/domain/open_wallet_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class OpenWalletStateRepository extends PersistentState<OpenWalletState> {
  OpenWalletStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _storageKey = 'open_wallets';

  @override
  OpenWalletState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _storageKey);
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
    return sharedPreferencesSync.delete(key: _storageKey);
  }

  @override
  Future<bool> localSave(OpenWalletState state) {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _storageKey,
      value: value,
    );
  }
}
