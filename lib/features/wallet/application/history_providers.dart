import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/event.dart';
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
  @override
  PagingState<int, MapEntry<DateTime, List<TransactionEntry>>> build() {
    ref.listen(walletStateProvider, (previous, next) {
      if (next.lastEvent is HistorySynced || next.lastEvent is NewTransaction) {
        ref.invalidateSelf();
      }
    });
    return PagingState();
  }

  void loading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setNextPage(
    int newKey,
    List<MapEntry<DateTime, List<TransactionEntry>>> txs,
  ) {
    state = state.copyWith(
      pages: [...?state.pages, txs],
      keys: [...?state.keys, newKey],
      hasNextPage: txs.isNotEmpty,
      isLoading: false,
    );
  }

  void error(Object error) {
    state = state.copyWith(error: error, isLoading: false);
  }
}
