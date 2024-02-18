import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/balance_mode_repository.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/balance_mode_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

part 'balance_mode_provider.g.dart';

@riverpod
class BalanceMode extends _$BalanceMode {
  @override
  BalanceModeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final balanceModeStateRepository =
        BalanceModeRepository(SharedPreferencesSync(prefs));
    return balanceModeStateRepository.fromStorage();
  }

  void setBalanceMode(BalanceModeState balanceModeState) {
    final prefs = ref.read(sharedPreferencesProvider);
    final balanceModeStateRepository =
        BalanceModeRepository(SharedPreferencesSync(prefs));
    state = balanceModeState;
    balanceModeStateRepository.localSave(state);
  }
}
