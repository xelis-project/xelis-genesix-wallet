import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/authentication/data/open_wallet_state_repository.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/open_wallet_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';

part 'open_wallet_state_provider.g.dart';

@riverpod
class OpenWallet extends _$OpenWallet {
  @override
  OpenWalletState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final openWalletStateRepository =
        OpenWalletStateRepository(SharedPreferencesSync(prefs));

    return openWalletStateRepository.fromStorage();
  }

  void saveOpenWalletState(String name, {String? address}) {
    final prefs = ref.read(sharedPreferencesProvider);
    final openWalletStateRepository =
        OpenWalletStateRepository(SharedPreferencesSync(prefs));

    if (address != null) {
      state = state.copyWith(
          walletCurrentlyUsed: name,
          wallets: {...state.wallets, name: address});
      openWalletStateRepository.localSave(state);
    } else {
      state = state.copyWith(walletCurrentlyUsed: name);
      openWalletStateRepository.localSave(state);
    }
  }
}
