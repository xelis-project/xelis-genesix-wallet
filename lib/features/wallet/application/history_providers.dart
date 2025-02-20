import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';

part 'history_providers.g.dart';

@riverpod
Future<List<TransactionEntry>> history(
  Ref ref,
  HistoryPageFilter filter,
) async {
  final repository = ref.watch(
    walletStateProvider.select((value) => value.nativeWalletRepository),
  );
  if (repository != null) {
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
