import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
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

  void setNodes(XelisNetwork network, List<NodeAddress> nodes) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkNodesStateRepository = NetworkNodesStateRepository(
      GenesixSharedPreferences(prefs),
    );
    final nextNodes = List<NodeAddress>.of(nodes);

    switch (network) {
      case XelisNetwork.mainnet:
        state = state.copyWith(mainnetNodes: nextNodes);
      case XelisNetwork.testnet:
        state = state.copyWith(testnetNodes: nextNodes);
      case XelisNetwork.devnet:
        state = state.copyWith(devnetNodes: nextNodes);
      case XelisNetwork.stagenet:
        state = state.copyWith(stagenetNodes: nextNodes);
    }

    networkNodesStateRepository.localSave(state);
  }

  void setNodeAddress(XelisNetwork network, NodeAddress address) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkNodesStateRepository = NetworkNodesStateRepository(
      GenesixSharedPreferences(prefs),
    );

    switch (network) {
      case XelisNetwork.mainnet:
        state = state.copyWith(mainnetAddress: address);
      case XelisNetwork.testnet:
        state = state.copyWith(testnetAddress: address);
      case XelisNetwork.devnet:
        state = state.copyWith(devnetAddress: address);
      case XelisNetwork.stagenet:
        state = state.copyWith(stagenetAddress: address);
    }

    networkNodesStateRepository.localSave(state);
  }

  void addNode(XelisNetwork network, NodeAddress nodeAddress) {
    if (!state.nodeExists(network, nodeAddress)) {
      final nodes = List<NodeAddress>.of(state.getNodes(network));
      nodes.add(nodeAddress);
      setNodes(network, nodes);
    }
  }

  void updateNode(
    XelisNetwork network,
    NodeAddress oldNodeAddress,
    NodeAddress newNodeAddress,
  ) {
    if (state.nodeExists(network, oldNodeAddress)) {
      final nodes = List<NodeAddress>.of(state.getNodes(network));
      final index = nodes.indexOf(oldNodeAddress);
      nodes[index] = newNodeAddress;
      setNodes(network, nodes);
    }
  }

  void removeNode(XelisNetwork network, NodeAddress nodeAddress) {
    if (state.nodeExists(network, nodeAddress)) {
      final nodes = List<NodeAddress>.of(state.getNodes(network));
      nodes.remove(nodeAddress);
      setNodes(network, nodes);
    }
  }
}
