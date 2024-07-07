import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:genesix/rust_bridge/api/table_generation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:localstorage/localstorage.dart';

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

    var walletExists = false;
    if (kIsWeb) {
      var path = localStorage.getItem(walletPath);
      walletExists = path != null;
    } else {
      walletExists = await Directory(walletPath).exists();
    }

    if (walletExists) {
      throw Exception('This wallet already exists: $name');
    } else {
      NativeWalletRepository walletRepository;

      // remove prefix for rust call because it's already appended
      var dbName = walletPath.replaceFirst(localStorageDBPrefix, "");
      if (seed != null) {
        walletRepository = await NativeWalletRepository.recover(
            dbName, password, settings.network,
            seed: seed, precomputeTablesPath: precomputedTablesPath);
      } else {
        walletRepository = await NativeWalletRepository.create(
            dbName, password, settings.network,
            precomputeTablesPath: precomputedTablesPath);
      }

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      state = AuthenticationState.signedIn(
          name: name, nativeWallet: walletRepository);

      ref.read(routerProvider).go(AuthAppScreen.wallet.toPath);

      try {
        ref.read(walletStateProvider.notifier).connect();
      } finally {
        // continue... it's ok if we can't connect
        // the connect() func displays an error message
      }

      if (seed == null) {
        final seed = await walletRepository.getSeed();

        ref
            .read(routerProvider)
            .push(AuthAppScreen.walletSeedDialog.toPath, extra: seed);
      }
    }
  }

  Future<void> openWallet(String name, String password) async {
    final settings = ref.read(settingsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();

    var walletPath = await getWalletPath(settings.network, name);

    var walletExists = false;
    if (kIsWeb) {
      var path = localStorage.getItem(walletPath);
      walletExists = path != null;
    } else {
      walletExists = await Directory(walletPath).exists();
    }

    if (walletExists) {
      NativeWalletRepository walletRepository;
      var dbName = walletPath.replaceFirst(localStorageDBPrefix, "");
      try {
        walletRepository = await NativeWalletRepository.open(
            dbName, password, settings.network,
            precomputeTablesPath: precomputedTablesPath);
      } catch (e) {
        rethrow;
      }

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      state = AuthenticationState.signedIn(
          name: name, nativeWallet: walletRepository);

      ref.read(routerProvider).go(AuthAppScreen.wallet.toPath);

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
    if (kIsWeb) {
      return "";
    } else {
      final dir = await getAppCacheDirPath();
      return "$dir/";
    }
  }

  Future<bool> isPrecomputedTablesExists() async {
    if (kIsWeb) {
      return true;
    } else {
      return precomputedTablesExist(
          precomputedTablesPath: await _getPrecomputedTablesPath());
    }
  }
}
