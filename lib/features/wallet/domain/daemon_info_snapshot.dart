import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

part 'daemon_info_snapshot.freezed.dart';

@freezed
abstract class DaemonInfoSnapshot with _$DaemonInfoSnapshot {
  const factory DaemonInfoSnapshot({
    @Default('') String height,
    @Default('') String topoHeight,
    @Default('') String stableHeight,
    @Default(false) bool pruned,
    @Default('') String circulatingSupply,
    @Default('') String maximumSupply,
    @Default('') String burnSupply,
    @Default('') String emittedSupply,
    @Default('') String hashRate,
    @Default(Duration()) Duration averageBlockTime,
    required BigInt mempoolSize,
    @Default('') String blockReward,
    @Default('') String version,
    wallet_flutter.XelisNetwork? network,
  }) = _DaemonInfoSnapshot;
}
