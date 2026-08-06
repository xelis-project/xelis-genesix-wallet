import 'package:genesix/shared/models/app_failure.dart';

/// Legacy hash-only broadcast result retained for multisig migration paths.
enum TransactionBroadcastResult {
  submitted,
  retryable,
  rejected,
  localFailure,
  submittedNeedsResync,
}

/// Disposition of an authored prepared-transaction broadcast attempt.
enum TransactionBroadcastDisposition {
  submitted,
  retryable,
  rejected,
  localFailure,
  submittedNeedsResync,
}

/// Genesix projection of one authored prepared-transaction broadcast result.
///
/// Every non-clean package result carries the support-safe [failure] recorded
/// exactly once by the command boundary. Its original `XWF-...` identifier is
/// preserved. A clean submission has no failure.
final class PreparedTransactionBroadcastResult {
  const PreparedTransactionBroadcastResult.submitted()
    : disposition = TransactionBroadcastDisposition.submitted,
      failure = null;

  const PreparedTransactionBroadcastResult.retryable({
    required AppFailure this.failure,
  }) : disposition = TransactionBroadcastDisposition.retryable;

  const PreparedTransactionBroadcastResult.rejected({
    required AppFailure this.failure,
  }) : disposition = TransactionBroadcastDisposition.rejected;

  const PreparedTransactionBroadcastResult.localFailure({
    required AppFailure this.failure,
  }) : disposition = TransactionBroadcastDisposition.localFailure;

  const PreparedTransactionBroadcastResult.submittedNeedsResync({
    required AppFailure this.failure,
  }) : disposition = TransactionBroadcastDisposition.submittedNeedsResync;

  final TransactionBroadcastDisposition disposition;
  final AppFailure? failure;
}
