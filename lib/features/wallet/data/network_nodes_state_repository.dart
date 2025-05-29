import 'package:genesix/shared/storage/persistent_state.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';

class NetworkNodesStateRepository extends PersistentState<NetworkNodesState> {
  NetworkNodesStateRepository(this.genesixSharedPreferences);

  GenesixSharedPreferences genesixSharedPreferences;
  static const storageKey = 'network_nodes';

  @override
  NetworkNodesState fromStorage() {
    try {
      final value = genesixSharedPreferences.get(key: storageKey);
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
  Future<void> localDelete() async {
    await genesixSharedPreferences.delete(key: storageKey);
  }

  @override
  Future<void> localSave(NetworkNodesState state) async {
    final value = state.toJson();
    await genesixSharedPreferences.save(key: storageKey, value: value);
  }
}
