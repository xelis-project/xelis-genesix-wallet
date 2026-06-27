import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:genesix/features/authentication/application/authentication_provider.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:genesix/features/authentication/domain/biometric_wallet_key.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/settings/data/settings_state_repository.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';

part 'settings_state_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final settingsStateRepository = SettingsStateRepository(
      GenesixSharedPreferences(prefs),
    );
    return settingsStateRepository.fromStorage();
  }

  void _setState(SettingsState state) {
    final prefs = ref.read(sharedPreferencesProvider);
    final settingsStateRepository = SettingsStateRepository(
      GenesixSharedPreferences(prefs),
    );
    settingsStateRepository.localSave(state);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _setState(state);
  }

  void setNetwork(Network network) {
    state = state.copyWith(network: network);
    _setState(state);
  }

  void setTheme(AppTheme theme) {
    state = state.copyWith(appTheme: theme);
    _setState(state);
  }

  void setHideBalance(bool hideBalance) {
    state = state.copyWith(hideBalance: hideBalance);
    _setState(state);
  }

  void setUnlockBurn(bool unlockBurn) {
    state = state.copyWith(unlockBurn: unlockBurn);
    _setState(state);
  }

  void setDisplayCurrency(String? displayCurrency) {
    state = state.copyWith(displayCurrency: displayCurrency);
    _setState(state);
  }

  void setEnableNewsFeed(bool enableNewsFeed) {
    state = state.copyWith(enableNewsFeed: enableNewsFeed);
    _setState(state);
  }

  void setActivateBiometricAuth(
    bool activateBiometricAuth, {
    bool syncWalletStorage = true,
  }) {
    state = state.copyWith(activateBiometricAuth: activateBiometricAuth);
    _setState(state);

    if (!syncWalletStorage || kIsWeb) {
      return;
    }

    final authState = ref.read(authenticationProvider);
    if (authState is! SignedIn) {
      return;
    }

    final secureStorage = ref.read(secureStorageProvider);
    final biometricKey = biometricWalletKey(
      network: state.network,
      walletName: authState.name,
    );

    unawaited(
      activateBiometricAuth
          ? secureStorage.write(key: biometricKey, value: '1')
          : _deleteWalletBiometricStorage(authState.name),
    );
  }

  Future<void> _deleteWalletBiometricStorage(String walletName) async {
    final secureStorage = ref.read(secureStorageProvider);
    final currentNetwork = state.network;
    await Future.wait<void>([
      secureStorage.delete(
        key: biometricWalletKey(
          network: currentNetwork,
          walletName: walletName,
        ),
      ),
      secureStorage.delete(
        key: walletPasswordKey(network: currentNetwork, walletName: walletName),
      ),
    ]);

    for (final network in Network.values) {
      if (network == currentNetwork) {
        continue;
      }
      final hasOtherBiometricWallet = await secureStorage.containsKey(
        key: biometricWalletKey(network: network, walletName: walletName),
      );
      if (hasOtherBiometricWallet) {
        return;
      }
    }

    await secureStorage.delete(
      key: legacyWalletPasswordKey(walletName: walletName),
    );
  }

  void setEnableXswd(bool enableXswd) {
    state = state.copyWith(enableXswd: enableXswd);
    _setState(state);
  }

  void setHistoryFilterState(HistoryFilterState historyFilterState) {
    state = state.copyWith(historyFilterState: historyFilterState);
    _setState(state);
  }

  void setLastMainnetWalletUsed(String name) {
    final lastUsedWallets = state.lastWalletsUsed.copyWith(mainnet: name);
    state = state.copyWith(lastWalletsUsed: lastUsedWallets);
    _setState(state);
  }

  void setLastTestnetWalletUsed(String name) {
    final lastUsedWallets = state.lastWalletsUsed.copyWith(testnet: name);
    state = state.copyWith(lastWalletsUsed: lastUsedWallets);
    _setState(state);
  }

  void setLastStagenetWalletUsed(String name) {
    final lastUsedWallets = state.lastWalletsUsed.copyWith(stagenet: name);
    state = state.copyWith(lastWalletsUsed: lastUsedWallets);
    _setState(state);
  }

  void setLastDevnetWalletUsed(String name) {
    final lastUsedWallets = state.lastWalletsUsed.copyWith(devnet: name);
    state = state.copyWith(lastWalletsUsed: lastUsedWallets);
    _setState(state);
  }
}
