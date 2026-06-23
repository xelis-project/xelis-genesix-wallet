import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'pending_transactions_provider.g.dart';

@riverpod
Future<List<TransactionPending>> pendingTransactions(Ref ref) async {
  ref.watch(walletHistoryRefreshSignalProvider);

  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository == null) {
    return [];
  }

  final txs = await repository.pendingTransactions();
  txs.sort((a, b) {
    final aTs = a.timestamp?.millisecondsSinceEpoch;
    final bTs = b.timestamp?.millisecondsSinceEpoch;
    if (aTs == null && bTs == null) {
      return a.hash.compareTo(b.hash);
    }
    if (aTs == null) return 1;
    if (bTs == null) return -1;
    return bTs.compareTo(aTs);
  });

  return txs;
}
