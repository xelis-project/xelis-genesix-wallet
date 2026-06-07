import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

part 'wallet_runtime_state.freezed.dart';

enum WalletConnectionPhase {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

@freezed
abstract class WalletRuntimeState with _$WalletRuntimeState {
  factory WalletRuntimeState({
    @Default(false) bool isOnline,
    @Default(false) bool isSyncing,
    @Default(false) bool isRescanning,
    @Default(WalletConnectionPhase.disconnected)
    WalletConnectionPhase connectionPhase,
    @Default(0) int topoheight,
    @Default('') String xelisBalance,
    required LinkedHashMap<String, String> trackedBalances,
    required LinkedHashMap<String, sdk.AssetData> knownAssets,
    @Default('') String address,
    @Default('') String name,
    @Default(MultisigState()) MultisigState multisigState,
    @Default(rust.Network.mainnet) rust.Network network,
    NodeAddress? selectedNode,
    String? lastConnectionError,
  }) = _WalletRuntimeState;
}
