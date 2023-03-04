import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_addresses_state.freezed.dart';

part 'node_addresses_state.g.dart';

@freezed
class NodeAddressesState with _$NodeAddressesState {
  const factory NodeAddressesState({
    required String favorite,
    @Default([]) List<String> nodeAddresses,
  }) = _NodeAddressesState;

  factory NodeAddressesState.fromJson(Map<String, dynamic> json) =>
      _$NodeAddressesStateFromJson(json);
}
