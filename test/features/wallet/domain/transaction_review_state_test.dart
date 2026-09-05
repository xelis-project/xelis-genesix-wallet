import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

void main() {
  group('TransactionReviewState prepared transaction binding', () {
    test('standard transfer retains the exact prepared object', () {
      final prepared = _preparedTransfer();
      final state = TransactionReviewState.singleTransferTransaction(
        asset: _asset,
        name: 'XELIS',
        ticker: 'XEL',
        amount: '90 071 992,54740993 XEL',
        fee: '0,00000100 XEL',
        destination: _destination,
        destinationAddress: const DestinationAddress(address: _destination),
        txHash: prepared.hash,
        prepared: prepared,
        sessionIdentity: _sessionIdentity,
      ) as SingleTransferTransaction;

      expect(state.prepared, same(prepared));
      expect(state.txHash, prepared.hash);

      final confirmed = state.copyWith(isConfirmed: true);
      expect(confirmed.prepared, same(prepared));
      expect(confirmed.txHash, prepared.hash);
    });

    test('standard burn retains the exact prepared object', () {
      final prepared = _preparedBurn();
      final state = TransactionReviewState.burnTransaction(
        asset: _asset,
        name: 'XELIS',
        ticker: 'XEL',
        amount: '90 071 992,54740993 XEL',
        fee: '0,00000200 XEL',
        txHash: prepared.hash,
        prepared: prepared,
        sessionIdentity: _sessionIdentity,
      ) as BurnTransaction;

      expect(state.prepared, same(prepared));
      expect(state.txHash, prepared.hash);

      final confirmed = state.copyWith(isConfirmed: true);
      expect(confirmed.prepared, same(prepared));
      expect(confirmed.txHash, prepared.hash);
    });

    test('multisig deletion retains the exact finalized capability', () {
      final prepared = _preparedMultisigDelete();
      final state = TransactionReviewState.deleteMultisigTransaction(
        fee: '0,00000300 XEL',
        txHash: prepared.hash,
        prepared: prepared,
        sessionIdentity: _sessionIdentity,
      ) as DeleteMultisigTransaction;

      expect(state.prepared, same(prepared));
      expect(state.txHash, prepared.hash);
      expect(
        state.prepared.details,
        isA<wallet_flutter.XelisWalletPreparedMultisigTransaction>(),
      );

      final confirmed = state.copyWith(isConfirmed: true);
      expect(confirmed.prepared, same(prepared));
      expect(confirmed.txHash, prepared.hash);
    });
  });
}

const _asset =
    '0000000000000000000000000000000000000000000000000000000000000000';
const _destination = 'xel:review-destination';
final _sessionIdentity = Object();

wallet_flutter.XelisWalletPreparedTransaction _preparedTransfer() {
  return wallet_flutter.XelisWalletPreparedTransaction(
    hash: 'prepared-transfer-hash',
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

wallet_flutter.XelisWalletPreparedTransaction _preparedBurn() {
  return wallet_flutter.XelisWalletPreparedTransaction(
    hash: 'prepared-burn-hash',
    feeAtomic: BigInt.from(200),
    details: wallet_flutter.XelisWalletPreparedBurn(
      asset: _asset,
      amountAtomic: (BigInt.one << 53) + BigInt.one,
    ),
  );
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
