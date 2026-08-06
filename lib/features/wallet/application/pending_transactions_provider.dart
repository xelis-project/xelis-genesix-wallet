import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:genesix/features/wallet/application/wallet_transaction_sorting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'pending_transactions_provider.g.dart';

@riverpod
Future<List<XelisWalletPendingTransaction>> pendingTransactions(Ref ref) async {
  ref.watch(walletHistoryRefreshSignalProvider);

  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository == null) {
    return [];
  }

  return sortPendingTransactionsNewestFirst(
    await repository.pendingTransactions(
      extraDataDisclosure: XelisWalletExtraDataDisclosure.metadata,
    ),
  );
}
