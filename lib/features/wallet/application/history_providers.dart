import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'history_providers.g.dart';

const pageSize = 30;

enum TransactionCategory { incoming, outgoing, coinbase, burn, blob }

@riverpod
Future<List<XelisWalletTransactionEntry>> history(Ref ref, int page) async {
  ref.watch(walletHistoryRefreshSignalProvider);
  final repository = ref.watch(activeWalletRepositoryProvider);
  final historyFilterState = ref.watch(
    settingsProvider.select((state) => state.historyFilterState),
  );

  if (repository != null) {
    final filter = XelisWalletHistoryFilter(
      page: BigInt.from(page),
      acceptIncoming: historyFilterState.showIncoming,
      acceptOutgoing: historyFilterState.showOutgoing,
      acceptCoinbase: historyFilterState.showCoinbase,
      acceptBurn: historyFilterState.showBurn,
      acceptBlob: historyFilterState.showBlob,
      limit: BigInt.from(pageSize),
      assetHash: historyFilterState.asset,
      destination: historyFilterState.address == null
          ? null
          : XelisWalletFlutter.parseAddress(
              address: historyFilterState.address!,
            ),
      minTimestampMillis: historyFilterState.minTimestamp != null
          ? BigInt.from(historyFilterState.minTimestamp!.millisecondsSinceEpoch)
          : null,
      maxTimestampMillis: historyFilterState.maxTimestamp != null
          ? BigInt.from(historyFilterState.maxTimestamp!.millisecondsSinceEpoch)
          : null,
    );

    return repository.history(
      filter: filter,
      extraDataDisclosure: XelisWalletExtraDataDisclosure.metadata,
    );
  }
  return [];
}

@riverpod
Future<BigInt?> historyCount(Ref ref) async {
  ref.watch(walletHistoryRefreshSignalProvider);
  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository != null) {
    return repository.getHistoryCount();
  }
  return null;
}

@riverpod
class HistoryPagingState extends _$HistoryPagingState {
  @override
  PagingState<int, MapEntry<DateTime, List<XelisWalletTransactionEntry>>>
  build() {
    ref.watch(activeWalletSessionProvider);
    ref.watch(walletHistoryRefreshSignalProvider);
    ref.watch(settingsProvider.select((state) => state.historyFilterState));
    return PagingState();
  }

  void loading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setNextPage(
    int newKey,
    List<MapEntry<DateTime, List<XelisWalletTransactionEntry>>> txs,
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
