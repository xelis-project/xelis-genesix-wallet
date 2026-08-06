// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
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

  bool nodeExists(XelisNetwork network, NodeAddress nodeAddress) {
    var nodes = getNodes(network);
    return nodes.contains(nodeAddress);
  }

  List<NodeAddress> getNodes(XelisNetwork network) {
    switch (network) {
      case XelisNetwork.mainnet:
        return mainnetNodes;
      case XelisNetwork.testnet:
        return testnetNodes;
      case XelisNetwork.devnet:
        return devnetNodes;
      case XelisNetwork.stagenet:
        return stagenetNodes;
    }
  }

  NodeAddress getNodeAddress(XelisNetwork network) {
    switch (network) {
      case XelisNetwork.mainnet:
        return mainnetAddress;
      case XelisNetwork.testnet:
        return testnetAddress;
      case XelisNetwork.devnet:
        return devnetAddress;
      case XelisNetwork.stagenet:
        return stagenetAddress;
    }
  }

  factory NetworkNodesState.fromJson(Map<String, dynamic> json) =>
      _$NetworkNodesStateFromJson(json);
}

extension NetworkNodesStateExtension on NetworkNodesState {
  List<NodeAddress> nodesFor(XelisNetwork network) {
    switch (network) {
      case XelisNetwork.mainnet:
        return mainnetNodes;
      case XelisNetwork.testnet:
        return testnetNodes;
      case XelisNetwork.devnet:
        return devnetNodes;
      case XelisNetwork.stagenet:
        return stagenetNodes;
    }
  }

  NodeAddress addressFor(XelisNetwork network) {
    switch (network) {
      case XelisNetwork.mainnet:
        return mainnetAddress;
      case XelisNetwork.testnet:
        return testnetAddress;
      case XelisNetwork.devnet:
        return devnetAddress;
      case XelisNetwork.stagenet:
        return stagenetAddress;
    }
  }
}
