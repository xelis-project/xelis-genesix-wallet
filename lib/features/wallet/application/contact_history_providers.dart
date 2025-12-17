import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';

part 'contact_history_providers.g.dart';

const pageSize = 30;

@riverpod
Future<List<TransactionEntry>> contactHistory(
  Ref ref,
  String contactAddress,
  int page,
) async {
  ref.watch(walletStateProvider.select((value) => value.trackedBalances));
  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );

  if (repository != null) {
    final filter = HistoryPageFilter(
      page: BigInt.from(page),
      acceptIncoming: true,
      acceptOutgoing: true,
      acceptCoinbase: true,
      acceptBurn: true,
      limit: BigInt.from(pageSize),
      address: contactAddress,
    );

    return repository.history(filter);
  }
  return [];
}

@riverpod
class ContactHistoryPagingState extends _$ContactHistoryPagingState {
  @override
  PagingState<int, MapEntry<DateTime, List<TransactionEntry>>> build(
    String contactAddress,
  ) {
    return PagingState();
  }

  void loading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setNextPage(
    int newKey,
    List<MapEntry<DateTime, List<TransactionEntry>>> newItems,
  ) {
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
