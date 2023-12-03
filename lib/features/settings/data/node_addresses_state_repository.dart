import 'package:xelis_mobile_wallet/features/settings/data/persistent_state.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/node_addresses_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class NodeAddressesStateRepository extends PersistentState<NodeAddressesState> {
  NodeAddressesStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _nodeAddressesStorageKey = 'persistentNodeAddresses';

  @override
  NodeAddressesState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _nodeAddressesStorageKey);
      if (value == null) {
        return NodeAddressesState(
          // TODO temp testnet address
          favorite: AppResources.officialTestnetNodeURL,
        );
      }
      return NodeAddressesState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('NodeAddressesStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() async {
    return sharedPreferencesSync.delete(key: _nodeAddressesStorageKey);
  }

  @override
  Future<bool> localSave(NodeAddressesState state) async {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _nodeAddressesStorageKey,
      value: value,
    );
  }
}
