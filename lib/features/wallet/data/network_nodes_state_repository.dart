import 'package:genesix/shared/storage/persistent_state.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_sync.dart';

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
      talker.critical('NetworkNodesStateRepository: $e');
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
