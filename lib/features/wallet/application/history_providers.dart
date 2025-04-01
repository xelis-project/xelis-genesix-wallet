import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';

part 'history_providers.g.dart';

const pageSize = 10;

@riverpod
Future<List<TransactionEntry>> history(Ref ref, int page) async {
  ref.watch(walletStateProvider.select((value) => value.assets));
  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );
  final historyFilterState = ref.watch(
    settingsProvider.select((state) => state.historyFilterState),
  );
  final searchQuery = ref.watch(historySearchQueryProvider);

  if (repository != null) {
    final filter = HistoryPageFilter(
      page: BigInt.from(page),
      acceptIncoming: historyFilterState.showIncoming,
      acceptOutgoing: historyFilterState.showOutgoing,
      acceptCoinbase: historyFilterState.showCoinbase,
      acceptBurn: historyFilterState.showBurn,
      limit: BigInt.from(pageSize),
      assetHash: historyFilterState.asset,
      address: searchQuery.isNotEmpty ? searchQuery : null,
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
  @override
  PagingState<int, TransactionEntry> build() {
    ref.watch(historySearchQueryProvider);
    return PagingState();
  }

  void loading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setNextPage(int newKey, List<TransactionEntry> newItems) {
    state = state.copyWith(
      pages: [...?state.pages, newItems],
      keys: [...?state.keys, newKey],
      hasNextPage: newItems.length == pageSize,
      isLoading: false,
    );
  }

  void error(Object error) {
    state = state.copyWith(error: error, isLoading: false);
  }
}

@riverpod
class HistorySearchQuery extends _$HistorySearchQuery {
  @override
  String build() {
    return '';
  }

  void clear() {
    if (state.isNotEmpty) {
      state = '';
    }
  }

  void change(String value) {
    state = value;
  }
}
