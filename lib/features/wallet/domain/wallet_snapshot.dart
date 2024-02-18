import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/daemon_info_snapshot.dart';

part 'wallet_snapshot.freezed.dart';

@freezed
class WalletSnapshot with _$WalletSnapshot {
  const factory WalletSnapshot({
    @Default(false) bool isOnline,
    @Default(0) int topoheight,
    @Default(0) int nonce,
    @Default('0.0') String xelisBalance,
    Map<String, int>? assets, // Atomic units
    @Default('') String address,
    @Default('') String name,
    NativeWalletRepository? nativeWalletRepository,
    @Default(DaemonInfoSnapshot()) DaemonInfoSnapshot daemonInfo,
  }) = _WalletSnapshot;
}
