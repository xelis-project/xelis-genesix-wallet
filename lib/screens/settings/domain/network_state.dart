import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_state.freezed.dart';
part 'network_state.g.dart';

enum NetworkType {
  dev,
  testnet,
  mainnet
}

@freezed
class NetworkState with _$NetworkState {
  const factory NetworkState(NetworkType networkType) = _NetworkState;

  factory NetworkState.fromJson(Map<String, dynamic> json) =>
      _$NetworkStateFromJson(json);
}
