import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/node_address.dart';

part 'network_nodes_state.freezed.dart';

part 'network_nodes_state.g.dart';

@freezed
class NetworkNodesState with _$NetworkNodesState {
  const NetworkNodesState._();

  const factory NetworkNodesState({
    @JsonKey(name: "mainnet_address") required NodeAddress mainnetAddress,
    @JsonKey(name: "mainnet_nodes") @Default([]) List<NodeAddress> mainnetNodes,
    @JsonKey(name: "testnet_address") required NodeAddress testnetAddress,
    @JsonKey(name: "testnet_nodes") @Default([]) List<NodeAddress> testnetNodes,
    @JsonKey(name: "dev_address") required NodeAddress devAddress,
    @JsonKey(name: "dev_nodes") @Default([]) List<NodeAddress> devNodes,
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
      case Network.dev:
        return devNodes;
    }
  }

  NodeAddress getNodeAddress(Network network) {
    switch (network) {
      case Network.mainnet:
        return mainnetAddress;
      case Network.testnet:
        return testnetAddress;
      case Network.dev:
        return devAddress;
    }
  }

  factory NetworkNodesState.fromJson(Map<String, dynamic> json) =>
      _$NetworkNodesStateFromJson(json);
}
