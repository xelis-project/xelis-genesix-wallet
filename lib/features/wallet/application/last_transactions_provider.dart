import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'last_transactions_provider.g.dart';

@riverpod
Future<List<TransactionEntry>> lastTransactions(Ref ref) async {
  ref.watch(walletStateProvider.select((value) => value.trackedBalances));
  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );

  if (repository != null) {
    return repository.history(
      HistoryPageFilter(
        page: BigInt.from(1),
        acceptIncoming: true,
        acceptOutgoing: true,
        acceptCoinbase: true,
        acceptBurn: true,
        limit: BigInt.from(5),
      ),
    );
  }
  return [];
}
