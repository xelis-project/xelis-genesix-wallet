import 'package:xelis_mobile_wallet/shared/storage/persistent_state.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/network_nodes_state.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

class NetworkNodesStateRepository extends PersistentState<NetworkNodesState> {
  NetworkNodesStateRepository(this.sharedPreferencesSync);

  SharedPreferencesSync sharedPreferencesSync;
  static const _storageKey = 'network_nodes';

  @override
  NetworkNodesState fromStorage() {
    try {
      final value = sharedPreferencesSync.get(key: _storageKey);
      if (value == null) {
        return NetworkNodesState(
          mainnetAddress: AppResources.mainnetNodes.first,
          mainnetNodes: AppResources.mainnetNodes,
          testnetAddress: AppResources.testnetNodes.first,
          testnetNodes: AppResources.testnetNodes,
          devAddress: AppResources.devNodes.first,
          devNodes: AppResources.devNodes,
        );
      }
      return NetworkNodesState.fromJson(value as Map<String, dynamic>);
    } catch (e) {
      logger.severe('NetworkNodesStateRepository: $e');
      rethrow;
    }
  }

  @override
  Future<bool> localDelete() async {
    return sharedPreferencesSync.delete(key: _storageKey);
  }

  @override
  Future<bool> localSave(NetworkNodesState state) async {
    final value = state.toJson();
    return sharedPreferencesSync.save(
      key: _storageKey,
      value: value,
    );
  }
}
