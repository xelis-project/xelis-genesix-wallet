import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';

part 'wallet_snapshot.freezed.dart';

@freezed
class WalletSnapshot with _$WalletSnapshot {
  const factory WalletSnapshot({
    @Default(false) bool isOnline,
    @Default(0) int topoheight,
    @Default(0) int nonce,
    @Default('') String xelisBalance,
    Map<String, int>? assets, // Atomic units
    @Default('') String address,
    @Default('') String name,
    NativeWalletRepository? nativeWalletRepository,
    StreamSubscription<void>? streamSubscription,
  }) = _WalletSnapshot;
}
