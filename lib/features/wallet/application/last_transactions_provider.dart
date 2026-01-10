import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'last_transactions_provider.g.dart';

@riverpod
List<TransactionEntry> lastTransactions(Ref ref) {
  // Watch the paging state so we react to changes
  ref.watch(historyPagingStateProvider);

  // Read from the master transaction map in history paging state
  final allTransactions = ref
      .read(historyPagingStateProvider.notifier)
      .allTransactions;

  if (allTransactions.isEmpty) {
    return [];
  }

  // Sort all transactions by topoheight descending
  final sorted = allTransactions.values.toList();
  sorted.sort((a, b) {
    final cmp = b.topoheight.compareTo(a.topoheight);
    if (cmp != 0) return cmp;
    final ta = a.timestamp;
    final tb = b.timestamp;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return tb.compareTo(ta);
  });

  // Return top 5 most recent
  return sorted.take(5).toList();
}
