import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';

part 'history_providers.g.dart';

const pageSize = 30;

enum TransactionCategory { incoming, outgoing, coinbase, burn }

@riverpod
Future<List<TransactionEntry>> history(Ref ref, int page) async {
  // DON'T watch trackedBalances - it causes refetch on every transaction during rescan
  // We update via events instead
  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );
  final historyFilterState = ref.watch(
    settingsProvider.select((state) => state.historyFilterState),
  );

  if (repository != null) {
    final filter = HistoryPageFilter(
      page: BigInt.from(page),
      acceptIncoming: historyFilterState.showIncoming,
      acceptOutgoing: historyFilterState.showOutgoing,
      acceptCoinbase: historyFilterState.showCoinbase,
      acceptBurn: historyFilterState.showBurn,
      limit: BigInt.from(pageSize),
      assetHash: historyFilterState.asset,
      address: historyFilterState.address,
    );

    return repository.history(filter);
  }
  return [];
}

@riverpod
Future<int?> historyCount(Ref ref) async {
  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );
  if (repository != null) {
    return repository.getHistoryCount();
  }
  return null;
}

@riverpod
class HistoryPagingState extends _$HistoryPagingState {
  // Master list of ALL loaded transactions (accessible to lastTransactionsProvider)
  final Map<String, TransactionEntry> allTransactions = {};
  int _lastFetchedPage = 0;
  bool _hasMorePages = true;

  // Batching mechanism (like cake_wallet)
  final List<TransactionEntry> _txBuffer = [];
  Timer? _batchTimer;
  bool _isProcessing = false;

  @override
  PagingState<int, MapEntry<DateTime, List<TransactionEntry>>> build() {
    // Register cleanup callback
    ref.onDispose(() {
      _batchTimer?.cancel();
    });

    return PagingState();
  }

  void loading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setNextPage(
    int newKey,
    List<MapEntry<DateTime, List<TransactionEntry>>> newItems,
  ) {
    // Count transactions in this fetch
    final txCount = newItems.fold<int>(
      0,
      (sum, group) => sum + group.value.length,
    );

    // Add all transactions to master list
    for (final group in newItems) {
      for (final tx in group.value) {
        allTransactions[tx.hash] = tx;
      }
    }

    // Track fetch progress
    _lastFetchedPage = newKey;
    _hasMorePages = txCount >= pageSize;

    // Rebuild all pages from master list
    _rebuildPages();
  }

  void error(Object error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void reset() {
    // Flush any pending batched transactions
    _batchTimer?.cancel();
    if (_txBuffer.isNotEmpty) {
      _processBatch();
    }

    allTransactions.clear();
    _lastFetchedPage = 0;
    _hasMorePages = true;
    state = PagingState();
  }

  void addTransaction(TransactionEntry tx) {
    // Buffer transaction for batched processing (like cake_wallet)
    _txBuffer.add(tx);

    // If buffer exceeds 1000 items, process immediately
    if (_txBuffer.length > 1000) {
      _batchTimer?.cancel();
      _processBatch();
    } else if (_batchTimer == null || !_batchTimer!.isActive) {
      // Schedule batch processing in 1 second
      _batchTimer = Timer(const Duration(seconds: 1), _processBatch);
    }
  }

  void _processBatch() {
    if (_isProcessing || _txBuffer.isEmpty) return;

    _isProcessing = true;
    final buffered = List<TransactionEntry>.from(_txBuffer);
    _txBuffer.clear();

    // Add all buffered transactions to master list (deduplicates by hash)
    for (final tx in buffered) {
      allTransactions[tx.hash] = tx;
    }

    // Rebuild pages once for entire batch
    _rebuildPages();

    _isProcessing = false;
  }

  void _rebuildPages() {
    if (allTransactions.isEmpty) {
      state = PagingState();
      return;
    }

    // Sort all transactions by topoheight descending
    final allTxList = allTransactions.values.toList();
    allTxList.sort((a, b) {
      final cmp = b.topoheight.compareTo(a.topoheight);
      if (cmp != 0) return cmp;
      final ta = a.timestamp;
      final tb = b.timestamp;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    // Paginate: split into chunks of pageSize
    final pages = <List<MapEntry<DateTime, List<TransactionEntry>>>>[];
    final keys = <int>[];

    for (var i = 0; i < allTxList.length; i += pageSize) {
      final pageNum = (i ~/ pageSize) + 1;
      final pageTxs = allTxList.skip(i).take(pageSize).toList();

      // Group by date
      final grouped = groupTransactionsByDateSorted2Levels(pageTxs);
      pages.add(grouped.entries.toList());
      keys.add(pageNum);
    }

    state = state.copyWith(
      pages: pages,
      keys: keys,
      hasNextPage: _hasMorePages,
      isLoading: false,
    );
  }

  int get nextPageToFetch => _lastFetchedPage + 1;

  // Flush any pending batched transactions immediately
  void flushBatch() {
    _batchTimer?.cancel();
    if (_txBuffer.isNotEmpty) {
      _processBatch();
    }
  }
}
