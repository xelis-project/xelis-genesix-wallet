import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/history_state.dart';

part 'history_provider.g.dart';

@riverpod
Future<HistoryState> history(HistoryRef ref) async {
  ref.watch(walletStateProvider.select((value) => value.assets));
  final repository = ref.watch(
      walletStateProvider.select((value) => value.nativeWalletRepository));

  HistoryState state = HistoryState(
    coinbaseEntries: <TransactionEntry>{},
    burnEntries: <TransactionEntry>{},
    incomingEntries: <TransactionEntry>{},
    outgoingEntries: <TransactionEntry>{},
  );

  if (repository != null) {
    final history = await repository.allHistory();
    for (var entry in history) {
      switch (entry.txEntryType) {
        case CoinbaseEntry():
          state.coinbaseEntries.add(entry);
        case BurnEntry():
          state.burnEntries.add(entry);
        case IncomingEntry():
          state.incomingEntries.add(entry);
        case OutgoingEntry():
          state.outgoingEntries.add(entry);
      }
    }
  }
  return state;
}
