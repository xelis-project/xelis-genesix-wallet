import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

part 'wallet_runtime_state.freezed.dart';

enum WalletConnectionPhase {
  disconnected,
  connecting,
  connected,
  reconnecting,
  offline,
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
    required BigInt topoheight,
    required BigInt xelisBalance,
    required LinkedHashMap<String, BigInt> trackedBalances,
    required LinkedHashMap<String, wallet_flutter.XelisWalletAssetMetadata>
    knownAssets,
    @Default('') String address,
    @Default('') String name,
    wallet_flutter.XelisWalletMultisigState? multisigState,
    @Default(wallet_flutter.XelisNetwork.mainnet)
    wallet_flutter.XelisNetwork network,
    NodeAddress? selectedNode,
    AppFailure? lastConnectionFailure,
  }) = _WalletRuntimeState;
}
