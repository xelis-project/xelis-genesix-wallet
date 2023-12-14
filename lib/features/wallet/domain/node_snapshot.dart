import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'node_snapshot.freezed.dart';

@freezed
class NodeSnapshot with _$NodeSnapshot {
  const factory NodeSnapshot({
    String? endpoint,
    String? version,
    int? topoHeight,
    bool? pruned,
    int? difficulty,
    int? supply,
    Network? network,
  }) = _NodeSnapshot;
}
