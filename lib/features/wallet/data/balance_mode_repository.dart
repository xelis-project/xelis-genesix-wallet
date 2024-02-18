import 'package:xelis_mobile_wallet/features/wallet/domain/balance_mode_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class BalanceModeRepository extends PersistentState<BalanceModeState> {
  BalanceModeRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _balanceModeStorageKey = 'persistentBalanceModeState';

  @override
  BalanceModeState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _balanceModeStorageKey);
      if (value == null) {
        return const BalanceModeState(hide: false);
      }
      return BalanceModeState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('BalanceModeStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() {
    return sharedPreferencesSync.delete(key: _balanceModeStorageKey);
  }

  @override
  Future<bool> localSave(BalanceModeState state) {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _balanceModeStorageKey,
      value: value,
    );
  }
}
