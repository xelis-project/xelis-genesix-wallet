import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

enum PreparedTransactionReviewAction {
  markBroadcasted,
  retainForRetry,
  resetAndClose,
  markBroadcastedNeedsResync,
}

String? transactionReviewHash(TransactionReviewState review) =>
    switch (review) {
      SingleTransferTransaction(:final txHash) ||
      BurnTransaction(:final txHash) ||
      DeleteMultisigTransaction(:final txHash) => txHash,
      _ => null,
    };

wallet_flutter.XelisWalletPreparedTransaction? transactionReviewPrepared(
  TransactionReviewState review,
) => switch (review) {
  SingleTransferTransaction(:final prepared) => prepared,
  BurnTransaction(:final prepared) => prepared,
  DeleteMultisigTransaction(:final prepared) => prepared,
  _ => null,
};

Object? transactionReviewSessionIdentity(TransactionReviewState review) =>
    switch (review) {
      SignaturePending(:final sessionIdentity) ||
      SingleTransferTransaction(:final sessionIdentity) ||
      BurnTransaction(:final sessionIdentity) ||
      DeleteMultisigTransaction(:final sessionIdentity) => sessionIdentity,
      _ => null,
    };

/// Whether [current] is still the exact confirmed review authenticated by the
/// user as [reviewed].
///
/// Every broadcastable transaction requires the same prepared-object identity
/// and the same hash after authentication.
bool isSameConfirmedTransactionReview(
  TransactionReviewState current,
  TransactionReviewState reviewed,
) {
  if (!current.isConfirmed ||
      !reviewed.isConfirmed ||
      current.runtimeType != reviewed.runtimeType) {
    return false;
  }

  final reviewedHash = transactionReviewHash(reviewed);
  final currentHash = transactionReviewHash(current);
  if (reviewedHash == null || currentHash != reviewedHash) {
    return false;
  }

  final reviewedPrepared = transactionReviewPrepared(reviewed);
  if (reviewedPrepared == null) return false;

  final currentPrepared = transactionReviewPrepared(current);
  return identical(currentPrepared, reviewedPrepared) &&
      reviewedPrepared.hash == reviewedHash &&
      currentPrepared?.hash == reviewedHash;
}

PreparedTransactionReviewAction preparedTransactionReviewAction(
  TransactionBroadcastDisposition disposition,
) => switch (disposition) {
  TransactionBroadcastDisposition.submitted =>
    PreparedTransactionReviewAction.markBroadcasted,
  TransactionBroadcastDisposition.retryable =>
    PreparedTransactionReviewAction.retainForRetry,
  TransactionBroadcastDisposition.rejected ||
  TransactionBroadcastDisposition.localFailure =>
    PreparedTransactionReviewAction.resetAndClose,
  TransactionBroadcastDisposition.submittedNeedsResync =>
    PreparedTransactionReviewAction.markBroadcastedNeedsResync,
};
