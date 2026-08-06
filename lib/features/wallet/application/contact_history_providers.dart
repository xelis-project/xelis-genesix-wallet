import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'contact_history_providers.g.dart';

const pageSize = 30;

@riverpod
Future<List<XelisWalletTransactionEntry>> contactHistory(
  Ref ref,
  String contactAddress,
  int page,
) async {
  ref.watch(walletHistoryRefreshSignalProvider);
  final repository = ref.watch(activeWalletRepositoryProvider);

  if (repository != null) {
    final filter = XelisWalletHistoryFilter(
      page: BigInt.from(page),
      acceptIncoming: true,
      acceptOutgoing: true,
      acceptCoinbase: true,
      acceptBurn: true,
      acceptBlob: false,
      limit: BigInt.from(pageSize),
      destination: XelisWalletFlutter.parseAddress(address: contactAddress),
    );

    return repository.history(
      filter: filter,
      extraDataDisclosure: XelisWalletExtraDataDisclosure.metadata,
    );
  }
  return [];
}

@riverpod
class ContactHistoryPagingState extends _$ContactHistoryPagingState {
  @override
  PagingState<int, MapEntry<DateTime, List<XelisWalletTransactionEntry>>> build(
    String contactAddress,
  ) {
    ref.watch(activeWalletSessionProvider);
    ref.watch(walletHistoryRefreshSignalProvider);
    return PagingState();
  }

  void loading() {
    state = state.copyWith(isLoading: true, error: null);
  }

  void setNextPage(
    int newKey,
    List<MapEntry<DateTime, List<XelisWalletTransactionEntry>>> newItems, {
    required int fetchedTransactionCount,
  }) {
    state = state.copyWith(
      pages: [...?state.pages, newItems],
      keys: [...?state.keys, newKey],
      hasNextPage: fetchedTransactionCount == pageSize,
      isLoading: false,
    );
  }

  void error(Object error) {
    state = state.copyWith(error: error, isLoading: false);
  }
}
