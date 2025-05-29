import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';

part 'transaction_review_state.freezed.dart';

@freezed
sealed class TransactionReviewState with _$TransactionReviewState {
  const factory TransactionReviewState.initial({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
  }) = Initial;

  const factory TransactionReviewState.signaturePending({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String hashToSign,
  }) = SignaturePending;

  const factory TransactionReviewState.singleTransferTransaction({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String asset,
    required String name,
    required String ticker,
    required String amount,
    required String fee,
    required String destination,
    required DestinationAddress destinationAddress,
    required String txHash,
  }) = SingleTransferTransaction;

  const factory TransactionReviewState.burnTransaction({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String asset,
    required String name,
    required String ticker,
    required String amount,
    required String fee,
    required String txHash,
  }) = BurnTransaction;

  const factory TransactionReviewState.deleteMultisigTransaction({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String fee,
    required String txHash,
  }) = DeleteMultisigTransaction;
}
