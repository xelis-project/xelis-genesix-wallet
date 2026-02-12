import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'contact_transactions_provider.g.dart';

@riverpod
class ContactTransactions extends _$ContactTransactions {
  static const int pageSize = 30;
  int _currentPage = 1;
  List<TransactionEntry> _allTransactions = [];
  bool _hasMore = true;

  @override
  Future<List<TransactionEntry>> build(String contactAddress) async {
    _currentPage = 1;
    _allTransactions = [];
    _hasMore = true;
    return loadMore();
  }

  Future<List<TransactionEntry>> loadMore() async {
    if (!_hasMore) return _allTransactions;

    final repository = ref.read(
      walletStateProvider.select((value) => value.nativeWalletRepository),
    );

    if (repository != null) {
      final filter = HistoryPageFilter(
        page: BigInt.from(_currentPage),
        acceptIncoming: true,
        acceptOutgoing: true,
        acceptCoinbase: true,
        acceptBurn: true,
        limit: BigInt.from(pageSize),
        assetHash: null,
        address: contactAddress,
      );

      final transactions = await repository.history(filter);

      if (transactions.length < pageSize) {
        _hasMore = false;
      }

      _allTransactions.addAll(transactions);
      _currentPage++;
      state = AsyncData(_allTransactions);
      return _allTransactions;
    }
    return [];
  }

  bool get hasMore => _hasMore;

  void reset() {
    _currentPage = 0;
    _allTransactions = [];
    _hasMore = true;
    ref.invalidateSelf();
  }
}
