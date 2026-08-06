import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/wallet_transaction_sorting.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('sorts an unmodifiable confirmed list without mutating its source', () {
    final source = List<XelisWalletTransactionEntry>.unmodifiable([
      _confirmed(hash: 'older', timestamp: 1, topoheight: 3),
      _confirmed(hash: 'newer-low', timestamp: 2, topoheight: 4),
      _confirmed(hash: 'newer-high', timestamp: 2, topoheight: 5),
    ]);

    final sorted = sortConfirmedTransactionsNewestFirst(source);

    expect(sorted.map((transaction) => transaction.hash), [
      'newer-high',
      'newer-low',
      'older',
    ]);
    expect(source.first.hash, 'older');
  });

  test('sorts an unmodifiable pending list without mutating its source', () {
    final source = List<XelisWalletPendingTransaction>.unmodifiable([
      _pending(hash: 'older', timestamp: 1),
      _pending(hash: 'b', timestamp: 2),
      _pending(hash: 'a', timestamp: 2),
    ]);

    final sorted = sortPendingTransactionsNewestFirst(source);

    expect(sorted.map((transaction) => transaction.hash), ['a', 'b', 'older']);
    expect(source.first.hash, 'older');
  });
}

XelisWalletTransactionEntry _confirmed({
  required String hash,
  required int timestamp,
  required int topoheight,
}) => XelisWalletTransactionEntry(
  hash: hash,
  topoheight: BigInt.from(topoheight),
  timestampMillis: BigInt.from(timestamp),
  entry: XelisWalletCoinbaseEntry(reward: BigInt.zero),
);

XelisWalletPendingTransaction _pending({
  required String hash,
  required int timestamp,
}) => XelisWalletPendingTransaction(
  hash: hash,
  timestampMillis: BigInt.from(timestamp),
  entry: XelisWalletCoinbaseEntry(reward: BigInt.zero),
);
