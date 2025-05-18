import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;

part 'wallet_snapshot.freezed.dart';

@freezed
abstract class WalletSnapshot with _$WalletSnapshot {
  const factory WalletSnapshot({
    @Default(false) bool isOnline,
    @Default(0) int topoheight,
    @Default('') String xelisBalance,
    @Default({}) Map<String, String> trackedBalances,
    @Default({}) Map<String, sdk.AssetData> knownAssets,
    @Default('') String address,
    @Default('') String name,
    @Default(MultisigState()) MultisigState multisigState,
    @Default(rust.Network.mainnet) rust.Network network,
    NativeWalletRepository? nativeWalletRepository,

    StreamSubscription<void>? streamSubscription,
  }) = _WalletSnapshot;
}
