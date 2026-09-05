import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

typedef PreparedTransactionFailureRecorder = AppFailure Function(
  wallet_flutter.XelisWalletException failure,
);

PreparedTransactionBroadcastResult projectPreparedTransactionBroadcastResult(
  wallet_flutter.XelisWalletBroadcastResult result, {
  required PreparedTransactionFailureRecorder recordFailure,
}) => switch (result) {
  wallet_flutter.XelisWalletBroadcastSubmitted() =>
    const PreparedTransactionBroadcastResult.submitted(),
  wallet_flutter.XelisWalletBroadcastRetryable(:final failure) =>
    PreparedTransactionBroadcastResult.retryable(
      failure: recordFailure(failure),
    ),
  wallet_flutter.XelisWalletBroadcastRejected(:final failure) =>
    PreparedTransactionBroadcastResult.rejected(
      failure: recordFailure(failure),
    ),
  wallet_flutter.XelisWalletBroadcastLocalFailure(:final failure) =>
    PreparedTransactionBroadcastResult.localFailure(
      failure: recordFailure(failure),
    ),
  wallet_flutter.XelisWalletBroadcastSubmittedNeedsResync(:final failure) =>
    PreparedTransactionBroadcastResult.submittedNeedsResync(
      failure: recordFailure(failure),
    ),
};

/// Requests the one reconciliation required by a submitted-needs-resync
/// result, while preserving that terminal broadcast disposition even when the
/// reconciliation itself fails.
Future<PreparedTransactionBroadcastResult>
reconcilePreparedTransactionBroadcastResult(
  PreparedTransactionBroadcastResult result, {
  required Future<void> Function() rescan,
  required void Function(Object error, StackTrace stackTrace) onRescanFailure,
}) async {
  if (result.disposition !=
      TransactionBroadcastDisposition.submittedNeedsResync) {
    return result;
  }

  try {
    await rescan();
  } catch (error, stackTrace) {
    onRescanFailure(error, stackTrace);
  }
  return result;
}
