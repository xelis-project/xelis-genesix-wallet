import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/transaction_review_policy.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

void main() {
  group('isSameConfirmedTransactionReview', () {
    test('accepts the same confirmed prepared object and hash', () {
      final prepared = _preparedTransfer();
      final reviewed = _review(prepared: prepared, isConfirmed: true);
      final current = reviewed.copyWith();

      expect(isSameConfirmedTransactionReview(current, reviewed), isTrue);
    });

    test('rejects either inactive confirmation', () {
      final prepared = _preparedTransfer();
      final confirmed = _review(prepared: prepared, isConfirmed: true);

      expect(
        isSameConfirmedTransactionReview(
          confirmed.copyWith(isConfirmed: false),
          confirmed,
        ),
        isFalse,
      );
      expect(
        isSameConfirmedTransactionReview(
          confirmed,
          confirmed.copyWith(isConfirmed: false),
        ),
        isFalse,
      );
    });

    test('rejects a changed review hash', () {
      final prepared = _preparedTransfer();
      final reviewed = _review(prepared: prepared, isConfirmed: true);

      expect(
        isSameConfirmedTransactionReview(
          reviewed.copyWith(txHash: 'different-hash'),
          reviewed,
        ),
        isFalse,
      );
    });

    test('rejects a reconstructed prepared object with the same fields', () {
      final reviewedPrepared = _preparedTransfer();
      final reconstructed = _preparedTransfer();
      final reviewed = _review(prepared: reviewedPrepared, isConfirmed: true);
      final current = _review(prepared: reconstructed, isConfirmed: true);

      expect(reconstructed.hash, reviewedPrepared.hash);
      expect(identical(reconstructed, reviewedPrepared), isFalse);
      expect(isSameConfirmedTransactionReview(current, reviewed), isFalse);
    });

    test('multisig deletion requires the same finalized capability', () {
      final reviewedPrepared = _preparedMultisigDelete();
      final reconstructed = _preparedMultisigDelete();
      final reviewed = _deleteReview(
        prepared: reviewedPrepared,
        isConfirmed: true,
      );
      final current = _deleteReview(prepared: reconstructed, isConfirmed: true);

      expect(
        isSameConfirmedTransactionReview(reviewed.copyWith(), reviewed),
        isTrue,
      );
      expect(isSameConfirmedTransactionReview(current, reviewed), isFalse);
    });
  });

  test('maps every broadcast disposition to its review action', () {
    expect(
      preparedTransactionReviewAction(
        TransactionBroadcastDisposition.submitted,
      ),
      PreparedTransactionReviewAction.markBroadcasted,
    );
    expect(
      preparedTransactionReviewAction(
        TransactionBroadcastDisposition.retryable,
      ),
      PreparedTransactionReviewAction.retainForRetry,
    );
    expect(
      preparedTransactionReviewAction(TransactionBroadcastDisposition.rejected),
      PreparedTransactionReviewAction.resetAndClose,
    );
    expect(
      preparedTransactionReviewAction(
        TransactionBroadcastDisposition.localFailure,
      ),
      PreparedTransactionReviewAction.resetAndClose,
    );
    expect(
      preparedTransactionReviewAction(
        TransactionBroadcastDisposition.submittedNeedsResync,
      ),
      PreparedTransactionReviewAction.markBroadcastedNeedsResync,
    );
  });
}

SingleTransferTransaction _review({
  required wallet_flutter.XelisWalletPreparedTransaction prepared,
  required bool isConfirmed,
}) {
  return TransactionReviewState.singleTransferTransaction(
    isConfirmed: isConfirmed,
    asset: _asset,
    name: 'XELIS',
    ticker: 'XEL',
    amount: '1 XEL',
    fee: '0.000001 XEL',
    destination: _destination,
    destinationAddress: const DestinationAddress(address: _destination),
    txHash: prepared.hash,
    prepared: prepared,
    sessionIdentity: _sessionIdentity,
  ) as SingleTransferTransaction;
}

wallet_flutter.XelisWalletPreparedTransaction _preparedTransfer() {
  return wallet_flutter.XelisWalletPreparedTransaction(
    hash: 'prepared-hash',
    feeAtomic: BigInt.from(100),
    details: wallet_flutter.XelisWalletPreparedTransfers(
      transfers: [
        wallet_flutter.XelisWalletPreparedTransfer(
          destination: _destination,
          asset: _asset,
          amountAtomic: (BigInt.one << 53) + BigInt.one,
          hasExtraData: false,
          extraDataEncrypted: true,
        ),
      ],
    ),
  );
}

DeleteMultisigTransaction _deleteReview({
  required wallet_flutter.XelisWalletPreparedTransaction prepared,
  required bool isConfirmed,
}) {
  return TransactionReviewState.deleteMultisigTransaction(
    isConfirmed: isConfirmed,
    fee: '0.000003 XEL',
    txHash: prepared.hash,
    prepared: prepared,
    sessionIdentity: _sessionIdentity,
  ) as DeleteMultisigTransaction;
}

wallet_flutter.XelisWalletPreparedTransaction _preparedMultisigDelete() {
  return wallet_flutter.XelisWalletPreparedTransaction(
    hash: 'prepared-multisig-delete-hash',
    feeAtomic: BigInt.from(300),
    details: const wallet_flutter.XelisWalletPreparedMultisigTransaction(
      transaction: wallet_flutter.XelisWalletMultisigDelete(),
    ),
  );
}

const _asset =
    '0000000000000000000000000000000000000000000000000000000000000000';
const _destination = 'xel:review-destination';
final _sessionIdentity = Object();
