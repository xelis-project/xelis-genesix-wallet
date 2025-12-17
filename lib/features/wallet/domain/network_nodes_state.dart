// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';

part 'network_nodes_state.freezed.dart';

part 'network_nodes_state.g.dart';

@Freezed(makeCollectionsUnmodifiable: false)
abstract class NetworkNodesState with _$NetworkNodesState {
  const NetworkNodesState._();

  const factory NetworkNodesState({
    @JsonKey(name: "mainnet_address")
    @Default(NodeAddress())
    NodeAddress mainnetAddress,
    @JsonKey(name: "mainnet_nodes") @Default([]) List<NodeAddress> mainnetNodes,
    @JsonKey(name: "testnet_address")
    @Default(NodeAddress())
    NodeAddress testnetAddress,
    @JsonKey(name: "testnet_nodes") @Default([]) List<NodeAddress> testnetNodes,
    @JsonKey(name: "dev_address")
    @Default(NodeAddress())
    NodeAddress devnetAddress,
    @JsonKey(name: "dev_nodes") @Default([]) List<NodeAddress> devnetNodes,
    @JsonKey(name: "stagenet_address")
    @Default(NodeAddress())
    NodeAddress stagenetAddress,
    @JsonKey(name: "stagenet_nodes")
    @Default([])
    List<NodeAddress> stagenetNodes,
  }) = _NetworkNodesState;

  bool nodeExists(Network network, NodeAddress nodeAddress) {
    var nodes = getNodes(network);
    return nodes.contains(nodeAddress);
  }

  List<NodeAddress> getNodes(Network network) {
    switch (network) {
      case Network.mainnet:
        return mainnetNodes;
      case Network.testnet:
        return testnetNodes;
      case Network.devnet:
        return devnetNodes;
      case Network.stagenet:
        return stagenetNodes;
    }
  }

  NodeAddress getNodeAddress(Network network) {
    switch (network) {
      case Network.mainnet:
        return mainnetAddress;
      case Network.testnet:
        return testnetAddress;
      case Network.devnet:
        return devnetAddress;
      case Network.stagenet:
        return stagenetAddress;
    }
  }

  factory NetworkNodesState.fromJson(Map<String, dynamic> json) =>
      _$NetworkNodesStateFromJson(json);
}

extension NetworkNodesStateExtension on NetworkNodesState {
  List<NodeAddress> nodesFor(Network network) {
    switch (network) {
      case Network.mainnet:
        return mainnetNodes;
      case Network.testnet:
        return testnetNodes;
      case Network.devnet:
        return devnetNodes;
      case Network.stagenet:
        return stagenetNodes;
    }
  }

  NodeAddress addressFor(Network network) {
    switch (network) {
      case Network.mainnet:
        return mainnetAddress;
      case Network.testnet:
        return testnetAddress;
      case Network.devnet:
        return devnetAddress;
      case Network.stagenet:
        return stagenetAddress;
    }
  }
}
