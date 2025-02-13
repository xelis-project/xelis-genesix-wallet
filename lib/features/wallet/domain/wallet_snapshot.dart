import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/shared/resources/app_resources.dart';

part 'wallet_snapshot.freezed.dart';

@freezed
class WalletSnapshot with _$WalletSnapshot {
  const factory WalletSnapshot({
    @Default(false) bool isOnline,
    @Default(0) int topoheight,
    // @Default(0) int nonce, // Not used on Dart side for now
    @Default('') String xelisBalance,
    @Default(AppResources.defaultAssets)
    Map<String, String>
    assets, // key: asset hash, value: balance (already formatted as string)
    @Default('') String address,
    @Default('') String name,
    @Default(MultisigState()) MultisigState multisigState,
    NativeWalletRepository? nativeWalletRepository,
    StreamSubscription<void>? streamSubscription,
  }) = _WalletSnapshot;
}
