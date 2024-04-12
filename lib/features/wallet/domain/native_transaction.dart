// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'native_transaction.freezed.dart';

part 'native_transaction.g.dart';

@freezed
class NativeTransaction with _$NativeTransaction {
  const factory NativeTransaction({
    @JsonKey(name: "hash") required String hash,
    @JsonKey(name: "version") required int version,
    @JsonKey(name: "source") required String source,
    @JsonKey(name: "data") required Map<String, dynamic> data,
    @JsonKey(name: "fee") required int fee,
    @JsonKey(name: "nonce") required int nonce,
    @JsonKey(name: "source_commitments")
    required List<Map<String, dynamic>> sourceCommitments,
    @JsonKey(name: "range_proof") required List<int> rangeProof,
    @JsonKey(name: "reference") required Map<String, dynamic> reference,
    @JsonKey(name: "signature") required String signature,
  }) = _NativeTransaction;

  factory NativeTransaction.fromJson(Map<String, dynamic> json) =>
      _$NativeTransactionFromJson(json);
}
