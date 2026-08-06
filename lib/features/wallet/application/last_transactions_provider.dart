import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:genesix/features/wallet/application/wallet_transaction_sorting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'last_transactions_provider.g.dart';

@riverpod
Future<List<XelisWalletTransactionEntry>> lastTransactions(Ref ref) async {
  ref.watch(walletHistoryRefreshSignalProvider);

  final repository = ref.watch(activeWalletRepositoryProvider);

  if (repository != null) {
    final txs = sortConfirmedTransactionsNewestFirst(
      await repository.history(
        filter: XelisWalletHistoryFilter(
          page: BigInt.from(1),
          acceptIncoming: true,
          acceptOutgoing: true,
          acceptCoinbase: true,
          acceptBurn: true,
          acceptBlob: true,
          limit: BigInt.from(pageSize),
        ),
        extraDataDisclosure: XelisWalletExtraDataDisclosure.metadata,
      ),
    );

    return txs.take(5).toList();
  }
  return [];
}
