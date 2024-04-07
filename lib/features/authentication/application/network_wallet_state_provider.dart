import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/features/authentication/data/network_wallet_state_repository.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/network_wallet_state.dart';
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

  void removeWallet(Network network, String name) {
    final prefs = ref.read(sharedPreferencesProvider);
    final networkWalletStateRepository =
        NetworkWalletStateRepository(SharedPreferencesSync(prefs));

    switch (network) {
      case Network.mainnet:
        var newName = state.openMainnet == name ? null : state.openMainnet;
        var newWallets = Map<String, String>.from(state.mainnetWallets);
        newWallets.remove(name);
        state =
            state.copyWith(openMainnet: newName, mainnetWallets: newWallets);
      case Network.testnet:
        var newName = state.openTestnet == name ? null : state.openTestnet;
        var newWallets = Map<String, String>.from(state.testnetWallets);
        newWallets.remove(name);
        state =
            state.copyWith(openTestnet: newName, testnetWallets: newWallets);
      case Network.dev:
        var newName = state.openDev == name ? null : state.openDev;
        var newWallets = Map<String, String>.from(state.devWallets);
        newWallets.remove(name);
        state = state.copyWith(openDev: newName, devWallets: newWallets);
    }

    networkWalletStateRepository.localSave(state);
  }
}
