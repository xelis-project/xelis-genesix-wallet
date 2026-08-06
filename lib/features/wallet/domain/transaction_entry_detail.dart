import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

typedef TransactionEntryDetailRequest = ({String hash, bool isPending});

/// In-memory transaction detail with a common shape for confirmed and pending
/// entries.
///
/// The route may initially provide a metadata-only instance. A detail provider
/// replaces it with an explicit detailed read while the screen is mounted.
final class TransactionEntryDetail {
  const TransactionEntryDetail._({
    required this.hash,
    required this.timestampMillis,
    required this.entry,
    required this.isPending,
    this.topoheight,
  });

  factory TransactionEntryDetail.confirmed(
    XelisWalletTransactionEntry transaction,
  ) => TransactionEntryDetail._(
    hash: transaction.hash,
    timestampMillis: transaction.timestampMillis,
    topoheight: transaction.topoheight,
    entry: transaction.entry,
    isPending: false,
  );

  factory TransactionEntryDetail.pending(
    XelisWalletPendingTransaction transaction,
  ) => TransactionEntryDetail._(
    hash: transaction.hash,
    timestampMillis: transaction.timestampMillis,
    entry: transaction.entry,
    isPending: true,
  );

  factory TransactionEntryDetail.fromRouteExtra(
    Object? value,
  ) => switch (value) {
    XelisWalletTransactionEntry() => TransactionEntryDetail.confirmed(value),
    XelisWalletPendingTransaction() => TransactionEntryDetail.pending(value),
    _ => throw const FormatException(
      'Transaction detail route requires a wallet transaction entry',
    ),
  };

  final String hash;
  final BigInt timestampMillis;
  final BigInt? topoheight;
  final XelisWalletTransactionEntryData entry;
  final bool isPending;

  TransactionEntryDetailRequest get request =>
      (hash: hash, isPending: isPending);
}
