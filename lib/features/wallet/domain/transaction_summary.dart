// ignore_for_file: invalid_annotation_target

import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/transaction_summary_type.dart';

part 'transaction_summary.freezed.dart';

part 'transaction_summary.g.dart';

@freezed
class TransactionSummary with _$TransactionSummary {
  const TransactionSummary._();

  const factory TransactionSummary({
    @JsonKey(name: "hash") required String hash,
    @JsonKey(name: "fee") required int fee,
    @JsonKey(name: "transaction_type")
    required TransactionSummaryType transactionSummaryType,
  }) = _TransactionSummary;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) =>
      _$TransactionSummaryFromJson(json);

  bool get isBurn => transactionSummaryType.burn != null;

  bool get isTransfer => transactionSummaryType.transferOutEntry != null;

  HashMap<String, int> getAmountsPerAsset() {
    final amounts = HashMap<String, int>();
    if (transactionSummaryType.transferOutEntry != null) {
      for (final entry in transactionSummaryType.transferOutEntry!) {
        if (amounts.containsKey(entry.asset)) {
          amounts[entry.asset] = amounts[entry.asset]! + entry.amount;
        } else {
          amounts[entry.asset] = entry.amount;
        }
      }
    }
    return amounts;
  }
}
