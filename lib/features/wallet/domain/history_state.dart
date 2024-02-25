import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'history_state.freezed.dart';

@Freezed(makeCollectionsUnmodifiable: false)
class HistoryState with _$HistoryState {
  factory HistoryState({
    required Set<TransactionEntry> coinbaseEntries,
    required Set<TransactionEntry> burnEntries,
    required Set<TransactionEntry> incomingEntries,
    required Set<TransactionEntry> outgoingEntries,
  }) = _HistoryState;
}
