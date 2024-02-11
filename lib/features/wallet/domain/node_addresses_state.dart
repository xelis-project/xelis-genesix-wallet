import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/node_address.dart';

part 'node_addresses_state.freezed.dart';

part 'node_addresses_state.g.dart';

@freezed
class NodeAddressesState with _$NodeAddressesState {
  const factory NodeAddressesState({
    required NodeAddress favorite,
    @Default([]) List<NodeAddress> nodeAddresses,
  }) = _NodeAddressesState;

  factory NodeAddressesState.fromJson(Map<String, dynamic> json) =>
      _$NodeAddressesStateFromJson(json);
}
