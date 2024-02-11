import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'daemon_info_snapshot.freezed.dart';

@freezed
class DaemonInfoSnapshot with _$DaemonInfoSnapshot {
  const factory DaemonInfoSnapshot({
    @Default(0) int height,
    @Default(0) int topoHeight,
    @Default(false) bool pruned,
    @Default(0) int circulatingSupply,
    @Default(0) int mempoolSize,
    @Default('') String version,
    Network? network,
  }) = _DaemonInfoSnapshot;
}
