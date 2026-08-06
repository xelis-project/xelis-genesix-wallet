import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Returns a mutable, newest-first copy of confirmed wallet transactions.
List<XelisWalletTransactionEntry> sortConfirmedTransactionsNewestFirst(
  Iterable<XelisWalletTransactionEntry> transactions,
) {
  final sorted = transactions.toList();
  sorted.sort((a, b) {
    final timestampComparison = b.timestampMillis.compareTo(a.timestampMillis);
    return timestampComparison != 0
        ? timestampComparison
        : b.topoheight.compareTo(a.topoheight);
  });
  return sorted;
}

/// Returns a mutable, newest-first copy of pending wallet transactions.
List<XelisWalletPendingTransaction> sortPendingTransactionsNewestFirst(
  Iterable<XelisWalletPendingTransaction> transactions,
) {
  final sorted = transactions.toList();
  sorted.sort((a, b) {
    final timestampComparison = b.timestampMillis.compareTo(a.timestampMillis);
    return timestampComparison != 0
        ? timestampComparison
        : a.hash.compareTo(b.hash);
  });
  return sorted;
}
