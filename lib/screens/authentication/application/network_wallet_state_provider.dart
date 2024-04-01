import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/screens/authentication/data/network_wallet_state_repository.dart';
import 'package:xelis_mobile_wallet/screens/authentication/domain/network_wallet_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';

part 'network_wallet_state_provider.g.dart';

@riverpod
class NetworkWallet extends _$NetworkWallet {
  @override
  NetworkWalletState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final networkWalletStateRepository =
        NetworkWalletStateRepository(SharedPreferencesSync(prefs));

    return networkWalletStateRepository.fromStorage();
  }

  void setWallet(Network network, String name, String addr) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkWalletStateRepository =
        NetworkWalletStateRepository(SharedPreferencesSync(prefs));

    switch (network) {
      case Network.mainnet:
        state = state.copyWith(
          openMainnet: name,
          mainnetWallets: {...state.mainnetWallets, name: addr},
        );
      case Network.testnet:
        state = state.copyWith(
          openTestnet: name,
          testnetWallets: {...state.testnetWallets, name: addr},
        );
      case Network.dev:
        state = state.copyWith(
          openDev: name,
          devWallets: {...state.devWallets, name: addr},
        );
    }

    networkWalletStateRepository.localSave(state);
  }
}
