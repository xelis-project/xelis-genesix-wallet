import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'daemon_info_snapshot.freezed.dart';

@freezed
abstract class DaemonInfoSnapshot with _$DaemonInfoSnapshot {
  const factory DaemonInfoSnapshot({
    @Default(0) int topoHeight,
    @Default(false) bool pruned,
    @Default('') String circulatingSupply,
    @Default('') String burnSupply,
    @Default(Duration()) Duration averageBlockTime,
    @Default(0) int mempoolSize,
    @Default('') String blockReward,
    @Default('') String version,
    Network? network,
  }) = _DaemonInfoSnapshot;
}
