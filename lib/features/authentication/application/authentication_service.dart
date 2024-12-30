import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/rust_bridge/api/table_generation.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
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
import 'package:io/io.dart';

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
    String? privateKey,
  ]) async {
    final loc = ref.read(appLocalizationsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();
    final settings = ref.read(settingsProvider);
    final walletPath = await getWalletPath(settings.network, name);

    var walletExists = false;
    if (kIsWeb) {
      final path = localStorage.getItem(walletPath);
      walletExists = path != null;
    } else {
      walletExists = await Directory(walletPath).exists();
    }

    if (walletExists) {
      throw Exception('This wallet already exists: $name');
    } else {
      NativeWalletRepository walletRepository;

      // remove prefix for rust call because it's already appended
      final dbName = walletPath.replaceFirst(localStorageDBPrefix, "");

      try {
        if (seed != null) {
          walletRepository = await NativeWalletRepository.recoverFromSeed(
              dbName, password, settings.network,
              seed: seed, precomputeTablesPath: precomputedTablesPath);
        } else if (privateKey != null) {
          walletRepository = await NativeWalletRepository.recoverFromPrivateKey(
              dbName, password, settings.network,
              privateKey: privateKey);
        } else {
          walletRepository = await NativeWalletRepository.create(
              dbName, password, settings.network,
              precomputeTablesPath: precomputedTablesPath);
        }
      } on AnyhowException catch (e) {
        talker.critical('Creating wallet failed: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.error_when_creating_wallet}:\n$xelisMessage');
        rethrow;
      } catch (e) {
        talker.critical('Creating wallet failed: $e');
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.error_when_creating_wallet);
        rethrow;
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
    final loc = ref.read(appLocalizationsProvider);
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
      } on AnyhowException catch (e) {
        talker.critical('Opening wallet failed: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.error_when_opening_wallet}:\n$xelisMessage');
        rethrow;
      } catch (e) {
        talker.critical('Opening wallet failed: $e');
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.error_when_opening_wallet);
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

  // only used for desktop wallet import
  Future<void> openImportedWallet(
      String sourcePath, String walletName, String password) async {
    final loc = ref.read(appLocalizationsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();
    final network = ref.read(settingsProvider).network;

    NativeWalletRepository walletRepository;
    try {
      final targetPath = await getWalletPath(network, walletName);
      await copyPath(sourcePath, targetPath);

      walletRepository = await NativeWalletRepository.open(
          targetPath, password, network,
          precomputeTablesPath: precomputedTablesPath);
    } on AnyhowException catch (e) {
      talker.critical('Opening wallet failed: $e');
      final xelisMessage = (e).message.split("\n")[0];
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError('${loc.error_when_opening_wallet}:\n$xelisMessage');
      rethrow;
    } catch (e) {
      talker.critical('Opening wallet failed: $e');
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError(loc.error_when_opening_wallet);
      rethrow;
    }

    ref
        .read(walletsProvider.notifier)
        .setWalletAddress(walletName, walletRepository.address);

    state = AuthenticationState.signedIn(
        name: walletName, nativeWallet: walletRepository);

    ref.read(routerProvider).go(AuthAppScreen.wallet.toPath);

    ref.read(walletStateProvider.notifier).connect();
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
    return precomputedTablesExist(
        precomputedTablesPath: await _getPrecomputedTablesPath());
  }
}
