import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
import 'package:genesix/features/wallet/data/network_nodes_state_repository.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_sync.dart';

part 'network_nodes_provider.g.dart';

@riverpod
class NetworkNodes extends _$NetworkNodes {
  @override
  NetworkNodesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final networkNodesStateRepository =
        NetworkNodesStateRepository(SharedPreferencesSync(prefs));
    return networkNodesStateRepository.fromStorage();
  }

  void setNodes(Network network, List<NodeAddress> nodes) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkNodesStateRepository =
        NetworkNodesStateRepository(SharedPreferencesSync(prefs));

    switch (network) {
      case Network.mainnet:
        state = state.copyWith(
          mainnetNodes: nodes,
        );
      case Network.testnet:
        state = state.copyWith(
          testnetNodes: nodes,
        );
      case Network.dev:
        state = state.copyWith(
          devNodes: nodes,
        );
    }

    networkNodesStateRepository.localSave(state);
  }

  void setNodeAddress(Network network, NodeAddress address) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkNodesStateRepository =
        NetworkNodesStateRepository(SharedPreferencesSync(prefs));

    switch (network) {
      case Network.mainnet:
        state = state.copyWith(
          mainnetAddress: address,
        );
      case Network.testnet:
        state = state.copyWith(
          testnetAddress: address,
        );
      case Network.dev:
        state = state.copyWith(
          devAddress: address,
        );
    }

    networkNodesStateRepository.localSave(state);
  }

  void addNode(Network network, NodeAddress nodeAddress) {
    if (!state.nodeExists(network, nodeAddress)) {
      var nodes = state.getNodes(network);
      setNodes(network, [...nodes, nodeAddress]);
    }
  }

  void removeNode(Network network, NodeAddress nodeAddress) {
    if (state.nodeExists(network, nodeAddress)) {
      var nodes = state.getNodes(network);
      final newNodes = [
        for (final item in nodes)
          if (item != nodeAddress) item,
      ];
      setNodes(network, newNodes);
    }
  }
}
