import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'history_state.freezed.dart';

@Freezed(makeCollectionsUnmodifiable: false)
class HistoryState with _$HistoryState {
  const HistoryState._();

  factory HistoryState({
    required Set<TransactionEntry> coinbaseEntries,
    required Set<TransactionEntry> burnEntries,
    required Set<TransactionEntry> incomingEntries,
    required Set<TransactionEntry> outgoingEntries,
    required Set<TransactionEntry> multisigEntries,
    required Set<TransactionEntry> invokeContractEntries,
    required Set<TransactionEntry> deployContractEntries,
  }) = _HistoryState;

  bool get noTransactionAvailable =>
      coinbaseEntries.isEmpty &&
      burnEntries.isEmpty &&
      incomingEntries.isEmpty &&
      outgoingEntries.isEmpty;
}
