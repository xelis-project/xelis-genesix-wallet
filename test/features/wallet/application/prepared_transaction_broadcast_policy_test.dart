import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/prepared_transaction_broadcast_policy.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('projectPreparedTransactionBroadcastResult', () {
    test('does not record a failure for a clean submission', () {
      var recordings = 0;

      final result = projectPreparedTransactionBroadcastResult(
        const XelisWalletBroadcastSubmitted(),
        recordFailure: (failure) {
          recordings++;
          return AppFailure.fromXelis(failure);
        },
      );

      expect(result.disposition, TransactionBroadcastDisposition.submitted);
      expect(result.failure, isNull);
      expect(recordings, 0);
    });

    test('records each non-clean XWF exactly once', () {
      final cases =
          <(XelisWalletBroadcastResult, TransactionBroadcastDisposition)>[
            (
              XelisWalletBroadcastRetryable(failure: _nativeFailure),
              TransactionBroadcastDisposition.retryable,
            ),
            (
              XelisWalletBroadcastRejected(failure: _nativeFailure),
              TransactionBroadcastDisposition.rejected,
            ),
            (
              XelisWalletBroadcastLocalFailure(failure: _nativeFailure),
              TransactionBroadcastDisposition.localFailure,
            ),
            (
              XelisWalletBroadcastSubmittedNeedsResync(failure: _nativeFailure),
              TransactionBroadcastDisposition.submittedNeedsResync,
            ),
          ];

      for (final (packageResult, expectedDisposition) in cases) {
        var recordings = 0;
        final result = projectPreparedTransactionBroadcastResult(
          packageResult,
          recordFailure: (failure) {
            recordings++;
            return AppFailure.fromXelis(failure);
          },
        );

        expect(result.disposition, expectedDisposition);
        expect(result.failure?.supportId, _nativeFailure.supportId);
        expect(recordings, 1);
      }
    });
  });

  group('reconcilePreparedTransactionBroadcastResult', () {
    test('does not rescan a disposition that does not require it', () async {
      var rescans = 0;
      final result = const PreparedTransactionBroadcastResult.submitted();

      final returned = await reconcilePreparedTransactionBroadcastResult(
        result,
        rescan: () async => rescans++,
        onRescanFailure: (_, _) => fail('Unexpected rescan failure'),
      );

      expect(returned, same(result));
      expect(rescans, 0);
    });

    test('requests exactly one rescan and preserves the result', () async {
      var rescans = 0;
      final result = PreparedTransactionBroadcastResult.submittedNeedsResync(
        failure: AppFailure.fromXelis(_nativeFailure),
      );

      final returned = await reconcilePreparedTransactionBroadcastResult(
        result,
        rescan: () async => rescans++,
        onRescanFailure: (_, _) => fail('Unexpected rescan failure'),
      );

      expect(returned, same(result));
      expect(rescans, 1);
    });

    test('preserves the terminal result when the rescan fails', () async {
      var rescans = 0;
      var failures = 0;
      final result = PreparedTransactionBroadcastResult.submittedNeedsResync(
        failure: AppFailure.fromXelis(_nativeFailure),
      );

      final returned = await reconcilePreparedTransactionBroadcastResult(
        result,
        rescan: () async {
          rescans++;
          throw StateError('rescan failed');
        },
        onRescanFailure: (error, stackTrace) {
          failures++;
          expect(error, isA<StateError>());
          expect(stackTrace, isNot(StackTrace.empty));
        },
      );

      expect(returned, same(result));
      expect(rescans, 1);
      expect(failures, 1);
    });
  });
}

const _nativeFailure = XelisWalletOperationException(
  source: XelisWalletErrorSource.xelisWallet,
  operation: XelisWalletOperation.walletTransactionBroadcast,
  code: XelisWalletErrorCode.daemonRejected,
  supportId: 'XWF-1111-2222-3333-4444-5555',
  diagnosticMessage: 'privileged transaction diagnostic',
  nativeKind: 'DAEMON_REJECTED',
  nativeCode: -32042,
);
