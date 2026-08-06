import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test(
    'covers all broadcast dispositions and preserves the XWF support ID',
    () {
      const supportId = 'XWF-1111-2222-3333-4444-5555';
      const nativeFailure = XelisWalletOperationException(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletTransactionBroadcast,
        code: XelisWalletErrorCode.daemonRejected,
        supportId: supportId,
        diagnosticMessage: 'privileged transaction diagnostic',
        nativeKind: 'DAEMON_REJECTED',
        nativeCode: -32042,
      );
      final failure = AppFailure.fromXelis(nativeFailure);
      final cases =
          <
            ({
              TransactionBroadcastDisposition disposition,
              PreparedTransactionBroadcastResult result,
              bool hasFailure,
            })
          >[
            (
              disposition: TransactionBroadcastDisposition.submitted,
              result: const PreparedTransactionBroadcastResult.submitted(),
              hasFailure: false,
            ),
            (
              disposition: TransactionBroadcastDisposition.retryable,
              result: PreparedTransactionBroadcastResult.retryable(
                failure: failure,
              ),
              hasFailure: true,
            ),
            (
              disposition: TransactionBroadcastDisposition.rejected,
              result: PreparedTransactionBroadcastResult.rejected(
                failure: failure,
              ),
              hasFailure: true,
            ),
            (
              disposition: TransactionBroadcastDisposition.localFailure,
              result: PreparedTransactionBroadcastResult.localFailure(
                failure: failure,
              ),
              hasFailure: true,
            ),
            (
              disposition: TransactionBroadcastDisposition.submittedNeedsResync,
              result: PreparedTransactionBroadcastResult.submittedNeedsResync(
                failure: failure,
              ),
              hasFailure: true,
            ),
          ];

      expect(cases.map((entry) => entry.disposition).toSet(), {
        ...TransactionBroadcastDisposition.values,
      });

      for (final entry in cases) {
        expect(entry.result.disposition, entry.disposition);
        if (!entry.hasFailure) {
          expect(entry.result.failure, isNull);
          continue;
        }

        expect(entry.result.failure, same(failure));
        expect(entry.result.failure!.supportId, supportId);
        expect(entry.result.failure!.supportReference, startsWith(supportId));
      }

      expect(failure.source, XelisWalletErrorSource.xelisWallet.name);
      expect(
        failure.operation,
        XelisWalletOperation.walletTransactionBroadcast.id,
      );
      expect(failure.code, XelisWalletErrorCode.daemonRejected.id);
      expect(failure.nativeKind, 'DAEMON_REJECTED');
      expect(failure.nativeCode, -32042);
      expect(
        failure.originContractVersion,
        XelisWalletErrorContract.currentVersion,
      );
      expect(
        failure.toString(),
        isNot(contains('privileged transaction diagnostic')),
      );
      expect(
        failure.supportReference,
        isNot(contains('privileged transaction diagnostic')),
      );
    },
  );
}
