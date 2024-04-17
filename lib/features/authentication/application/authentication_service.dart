import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
import 'package:genesix/shared/utils/utils.dart';

part 'authentication_service.g.dart';

@riverpod
class Authentication extends _$Authentication {
  @override
  AuthenticationState build() {
    return const AuthenticationState.signedOut();
  }

  Future<void> createWallet(
    String name,
    String password, [
    String? seed,
  ]) async {
    final precomputedTablesPath = await _getPrecomputedTablesPath();
    final settings = ref.read(settingsProvider);
    var walletPath = await getWalletPath(settings.network, name);
    var walletExists = await Directory(walletPath).exists();

    if (walletExists) {
      throw Exception('This wallet already exists: $name');
    } else {
      NativeWalletRepository walletRepository;

      if (seed != null) {
        walletRepository = await NativeWalletRepository.recover(
            walletPath, password, settings.network,
            seed: seed, precomputeTablesPath: precomputedTablesPath);
      } else {
        walletRepository = await NativeWalletRepository.create(
            walletPath, password, settings.network,
            precomputeTablesPath: precomputedTablesPath);
      }

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      ref.read(routerProvider).go(AppScreen.wallet.toPath);

      state = AuthenticationState.signedIn(
          name: name, nativeWallet: walletRepository);

      ref.read(walletStateProvider.notifier).connect();
    }
  }

  Future<void> openWallet(String name, String password) async {
    final settings = ref.read(settingsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();

    var walletPath = await getWalletPath(settings.network, name);
    var walletExists = await Directory(walletPath).exists();

    if (walletExists) {
      NativeWalletRepository walletRepository;
      try {
        walletRepository = await NativeWalletRepository.open(
            walletPath, password, settings.network,
            precomputeTablesPath: precomputedTablesPath);
      } catch (e) {
        rethrow;
      }

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      state = AuthenticationState.signedIn(
          name: name, nativeWallet: walletRepository);

      ref.read(routerProvider).go(AppScreen.wallet.toPath);

      ref.read(walletStateProvider.notifier).connect();
    } else {
      throw Exception('This wallet does not exist: $name');
    }
  }

  Future<void> logout() async {
    switch (state) {
      case SignedIn(:final nativeWallet):
        await ref.read(walletStateProvider.notifier).disconnect();
        nativeWallet.dispose();
        state = const AuthenticationState.signedOut();

        ref.read(routerProvider).go(AppScreen.openWallet.toPath);

      case SignedOut():
        return;
    }
  }

  Future<String> _getPrecomputedTablesPath() async {
    final dir = await getApplicationCacheDirectory();
    return "${dir.path}/";
  }

  Future<bool> isPrecomputedTablesExists() async {
    return precomputedTablesExist(
        precomputedTablesPath: await _getPrecomputedTablesPath());
  }
}
