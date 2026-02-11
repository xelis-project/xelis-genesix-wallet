import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'last_transactions_provider.g.dart';

@riverpod
Future<List<TransactionEntry>> lastTransactions(Ref ref) async {
  ref.watch(historyPagingStateProvider);

  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );

  if (repository != null) {
    final txs = await repository.history(
      HistoryPageFilter(
        page: BigInt.from(1),
        acceptIncoming: true,
        acceptOutgoing: true,
        acceptCoinbase: true,
        acceptBurn: true,
        limit: BigInt.from(pageSize),
      ),
    );

    txs.sort((a, b) {
      final aTs = a.timestamp?.millisecondsSinceEpoch;
      final bTs = b.timestamp?.millisecondsSinceEpoch;
      if (aTs == null && bTs == null) {
        return b.topoheight.compareTo(a.topoheight);
      }
      if (aTs == null) return 1;
      if (bTs == null) return -1;

      final tsCompare = bTs.compareTo(aTs);
      if (tsCompare != 0) return tsCompare;

      return b.topoheight.compareTo(a.topoheight);
    });

    return txs.take(4).toList();
  }
  return [];
}
