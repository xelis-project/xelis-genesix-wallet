// ignore_for_file: invalid_annotation_target

import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'transaction_summary.freezed.dart';

@freezed
abstract class TransactionSummary with _$TransactionSummary {
  const TransactionSummary._();

  const factory TransactionSummary({
    @JsonKey(name: "hash") required String hash,
    @JsonKey(name: "fee") required int fee,
    @JsonKey(name: "transaction_type")
    required TransactionTypeBuilder transactionType,
  }) = _TransactionSummary;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      hash: json['hash'] as String,
      fee: json['fee'] as int,
      transactionType: TransactionTypeBuilderSafe.safeFromJson(
        json['transaction_type'] as Map<String, dynamic>,
      ),
    );
  }

  bool get isMultiSig => transactionType is MultisigBuilder;

  bool get isBurn => transactionType is BurnBuilder;

  bool get isTransfer => transactionType is TransfersBuilder;

  bool get isMultiTransfer {
    return isTransfer &&
        (transactionType as TransfersBuilder).transfers.length > 1;
  }

  bool get isXelisTransfer {
    if (!isMultiTransfer) {
      final transfer = getSingleTransfer();
      return transfer.asset == xelisAsset;
    }
    return false;
  }

  TransferBuilder getSingleTransfer() {
    return (transactionType as TransfersBuilder).transfers.first;
  }

  BurnBuilder getBurn() {
    return (transactionType as BurnBuilder);
  }

  HashMap<String, int> getAmountsPerAsset() {
    final amounts = HashMap<String, int>();
    if (isTransfer) {
      for (final transferBuilder
          in (transactionType as TransfersBuilder).transfers) {
        if (amounts.containsKey(transferBuilder.asset)) {
          amounts[transferBuilder.asset] =
              amounts[transferBuilder.asset]! + transferBuilder.amount;
        } else {
          amounts[transferBuilder.asset] = transferBuilder.amount;
        }
      }
    }
    return amounts;
  }
}
