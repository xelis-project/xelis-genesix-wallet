import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_history_refresh_signal_provider.g.dart';

@riverpod
class WalletHistoryRefreshSignal extends _$WalletHistoryRefreshSignal {
  @override
  int build() {
    return 0;
  }

  void bump() {
    state++;
  }
}
