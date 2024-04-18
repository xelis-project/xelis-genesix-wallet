// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/transaction_summary_type.dart';

part 'transaction_summary.freezed.dart';

part 'transaction_summary.g.dart';

@freezed
class TransactionSummary with _$TransactionSummary {
  const factory TransactionSummary({
    @JsonKey(name: "hash") required String hash,
    @JsonKey(name: "amount") required int amount,
    @JsonKey(name: "fee") required int fee,
    @JsonKey(name: "transaction_type")
    required TransactionSummaryType transactionSummaryType,
  }) = _TransactionSummary;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) =>
      _$TransactionSummaryFromJson(json);
}
