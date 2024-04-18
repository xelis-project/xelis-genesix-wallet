// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'transaction_summary_type.freezed.dart';

part 'transaction_summary_type.g.dart';

@freezed
class TransactionSummaryType with _$TransactionSummaryType {
  const factory TransactionSummaryType({
    @JsonKey(name: "transfers") List<TransferOutEntry>? transferOutEntry,
    @JsonKey(name: "burn") Burn? burn,
  }) = _TransactionSummaryType;

  factory TransactionSummaryType.fromJson(Map<String, dynamic> json) =>
      _$TransactionSummaryTypeFromJson(json);
}
