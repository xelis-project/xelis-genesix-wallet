import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/shared/resources/app_resources.dart';

part 'transaction_review_state.freezed.dart';

@freezed
abstract class TransactionReviewState with _$TransactionReviewState {
  const TransactionReviewState._();

  const factory TransactionReviewState({
    @Default(false) bool isBroadcast,
    @Default(false) bool isConfirmed,
    String? transactionHashToSign,
    TransactionSummary? summary,
    String? asset,
    Future<String>? amount,
    String? fee,
    String? destination,
    DestinationAddress? destinationAddress,
    String? finalHash,
  }) = _TransactionReviewState;

  bool get hasToBeSigned => transactionHashToSign != null;

  bool get hasSummary => summary != null;

  bool get isXelisTransfer => asset == AppResources.xelisAsset.hash;
}
