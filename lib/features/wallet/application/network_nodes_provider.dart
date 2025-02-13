import 'package:genesix/src/generated/rust_bridge/api/network.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/wallet/data/network_nodes_state_repository.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';

part 'network_nodes_provider.g.dart';

@riverpod
class NetworkNodes extends _$NetworkNodes {
  @override
  NetworkNodesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final networkNodesStateRepository = NetworkNodesStateRepository(
      GenesixSharedPreferences(prefs),
    );
    return networkNodesStateRepository.fromStorage();
  }

  void setNodes(Network network, List<NodeAddress> nodes) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkNodesStateRepository = NetworkNodesStateRepository(
      GenesixSharedPreferences(prefs),
    );

    switch (network) {
      case Network.mainnet:
        state = state.copyWith(mainnetNodes: nodes);
      case Network.testnet:
        state = state.copyWith(testnetNodes: nodes);
      case Network.dev:
        state = state.copyWith(devNodes: nodes);
    }

    networkNodesStateRepository.localSave(state);
  }

  void setNodeAddress(Network network, NodeAddress address) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkNodesStateRepository = NetworkNodesStateRepository(
      GenesixSharedPreferences(prefs),
    );

    switch (network) {
      case Network.mainnet:
        state = state.copyWith(mainnetAddress: address);
      case Network.testnet:
        state = state.copyWith(testnetAddress: address);
      case Network.dev:
        state = state.copyWith(devAddress: address);
    }

    networkNodesStateRepository.localSave(state);
  }

  void addNode(Network network, NodeAddress nodeAddress) {
    if (!state.nodeExists(network, nodeAddress)) {
      final nodes = state.getNodes(network);
      nodes.add(nodeAddress);
      setNodes(network, nodes);
    }
  }

  void updateNode(
    Network network,
    NodeAddress oldNodeAddress,
    NodeAddress newNodeAddress,
  ) {
    if (state.nodeExists(network, oldNodeAddress)) {
      var nodes = state.getNodes(network);
      final index = nodes.indexOf(oldNodeAddress);
      nodes[index] = newNodeAddress;
      setNodes(network, nodes);
    }
  }

  void removeNode(Network network, NodeAddress nodeAddress) {
    if (state.nodeExists(network, nodeAddress)) {
      var nodes = state.getNodes(network);
      nodes.remove(nodeAddress);
      setNodes(network, nodes);
    }
  }
}
