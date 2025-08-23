import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/storage/secure_storage/secure_storage_repository.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/src/generated/rust_bridge/api/precomputed_tables.dart';
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
  late SecureStorageRepository _secureStorage;

  @override
  AuthenticationState build() {
    _secureStorage = ref.watch(secureStorageProvider);
    return const AuthenticationState.signedOut();
  }

  Future<void> createWallet(
    String name,
    String password, {
    String? seed,
    String? privateKey,
  }) async {
    final loc = ref.read(appLocalizationsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();
    final settings = ref.read(settingsProvider);
    final walletPath = await getWalletPath(settings.network, name);
    final tableType = await _getTableType();
    talker.info('Precomputed tables type that will be used: $tableType');

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
            dbName,
            password,
            settings.network,
            seed: seed,
            precomputeTablesPath: precomputedTablesPath,
            precomputedTableType: tableType,
          );
        } else if (privateKey != null) {
          walletRepository = await NativeWalletRepository.recoverFromPrivateKey(
            dbName,
            password,
            settings.network,
            privateKey: privateKey,
            precomputedTableType: tableType,
          );
        } else {
          walletRepository = await NativeWalletRepository.create(
            dbName,
            password,
            settings.network,
            precomputeTablesPath: precomputedTablesPath,
            precomputedTableType: tableType,
          );
        }
      } on AnyhowException catch (e) {
        talker.critical('Creating wallet failed: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref
            .read(toastProvider.notifier)
            .showError(
              title: loc.error_when_creating_wallet,
              description: xelisMessage,
            );
        return;
      } catch (e) {
        talker.critical('Creating wallet failed: $e');
        ref
            .read(toastProvider.notifier)
            .showError(
              title: loc.error_when_creating_wallet,
              description: e.toString(),
            );
        return;
      }

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      // save password in secure storage on all platforms except web
      if (!kIsWeb) {
        await _secureStorage.write(key: name, value: password);
      }

      state = AuthenticationState.signedIn(
        name: name,
        nativeWallet: walletRepository,
      );

      switch (settings.network) {
        case Network.mainnet:
          ref.read(settingsProvider.notifier).setLastMainnetWalletUsed(name);
        case Network.testnet:
          ref.read(settingsProvider.notifier).setLastTestnetWalletUsed(name);
        case Network.devnet:
          ref.read(settingsProvider.notifier).setLastDevnetWalletUsed(name);
        case Network.stagenet:
          ref.read(settingsProvider.notifier).setLastStagenetWalletUsed(name);
      }

      if (seed == null) {
        final seed = await walletRepository.getSeed();
        ref.read(routerProvider).go(AuthAppScreen.home.toPath, extra: seed);
      } else {
        // if seed is provided, we don't need to show it
        // just navigate to the wallet screen
        ref.read(routerProvider).go(AuthAppScreen.home.toPath);
      }

      try {
        ref.read(walletStateProvider.notifier).connect();
      } finally {
        // continue... it's ok if we can't connect
        // the connect() func displays an error message
      }

      _updatePrecomputedTables(walletRepository, precomputedTablesPath);
    }
  }

  Future<void> openWallet(String name, String password) async {
    final loc = ref.read(appLocalizationsProvider);
    final settings = ref.read(settingsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();
    final tableType = await _getTableType();
    talker.info('Precomputed tables type that will be used: $tableType');

    final walletPath = await getWalletPath(settings.network, name);

    var walletExists = false;
    if (kIsWeb) {
      walletExists = localStorage.getItem(walletPath) != null;
    } else {
      walletExists = await Directory(walletPath).exists();
    }

    if (walletExists) {
      NativeWalletRepository walletRepository;
      final dbName = walletPath.replaceFirst(localStorageDBPrefix, "");
      try {
        walletRepository = await NativeWalletRepository.open(
          dbName,
          password,
          settings.network,
          precomputeTablesPath: precomputedTablesPath,
          precomputedTableType: tableType,
        );
      } on AnyhowException catch (e) {
        talker.critical('Opening wallet failed: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref
            .read(toastProvider.notifier)
            .showError(
              title: loc.error_when_opening_wallet,
              description: xelisMessage,
            );
        return;
      } catch (e) {
        talker.critical('Opening wallet failed: $e');
        ref
            .read(toastProvider.notifier)
            .showError(
              title: loc.error_when_opening_wallet,
              description: e.toString(),
            );
        return;
      }

      // save password in secure storage on all platforms except web
      if (!kIsWeb && !await _secureStorage.containsKey(key: name)) {
        await _secureStorage.write(key: name, value: password);
      }

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      state = AuthenticationState.signedIn(
        name: name,
        nativeWallet: walletRepository,
      );

      switch (settings.network) {
        case Network.mainnet:
          ref.read(settingsProvider.notifier).setLastMainnetWalletUsed(name);
        case Network.testnet:
          ref.read(settingsProvider.notifier).setLastTestnetWalletUsed(name);
        case Network.devnet:
          ref.read(settingsProvider.notifier).setLastDevnetWalletUsed(name);
        case Network.stagenet:
          ref.read(settingsProvider.notifier).setLastStagenetWalletUsed(name);
      }

      // final seed = await walletRepository.getSeed();
      // ref.read(routerProvider).go(AuthAppScreen.wallet.toPath, extra: seed);
      ref.read(routerProvider).go(AuthAppScreen.home.toPath);

      ref.read(walletStateProvider.notifier).connect();

      _updatePrecomputedTables(walletRepository, precomputedTablesPath);
    } else {
      throw Exception('This wallet does not exist: $name');
    }
  }

  // only used for desktop wallet import
  Future<void> openImportedWallet(
    String sourcePath,
    String walletName,
    String password,
  ) async {
    final loc = ref.read(appLocalizationsProvider);
    final network = ref.read(settingsProvider).network;
    final precomputedTablesPath = await _getPrecomputedTablesPath();
    final tableType = await _getTableType();
    talker.info('Precomputed tables type that will be used: $tableType');

    NativeWalletRepository walletRepository;
    try {
      final targetPath = await getWalletPath(network, walletName);
      await copyPath(sourcePath, targetPath);

      walletRepository = await NativeWalletRepository.open(
        targetPath,
        password,
        network,
        precomputeTablesPath: precomputedTablesPath,
        precomputedTableType: tableType,
      );
    } on AnyhowException catch (e) {
      talker.critical('Opening wallet failed: $e');
      final xelisMessage = (e).message.split("\n")[0];
      ref
          .read(toastProvider.notifier)
          .showError(
            title: loc.error_when_opening_wallet,
            description: xelisMessage,
          );
      return;
    } catch (e) {
      talker.critical('Opening wallet failed: $e');
      ref
          .read(toastProvider.notifier)
          .showError(
            title: loc.error_when_opening_wallet,
            description: e.toString(),
          );
      return;
    }

    // save password in secure storage on all platforms except web
    if (!kIsWeb && !await _secureStorage.containsKey(key: walletName)) {
      await _secureStorage.write(key: walletName, value: password);
    }

    ref
        .read(walletsProvider.notifier)
        .setWalletAddress(walletName, walletRepository.address);

    state = AuthenticationState.signedIn(
      name: walletName,
      nativeWallet: walletRepository,
    );

    switch (network) {
      case Network.mainnet:
        ref
            .read(settingsProvider.notifier)
            .setLastMainnetWalletUsed(walletName);
      case Network.testnet:
        ref
            .read(settingsProvider.notifier)
            .setLastTestnetWalletUsed(walletName);
      case Network.devnet:
        ref.read(settingsProvider.notifier).setLastDevnetWalletUsed(walletName);
      case Network.stagenet:
        ref
            .read(settingsProvider.notifier)
            .setLastStagenetWalletUsed(walletName);
    }

    final seed = await walletRepository.getSeed();
    ref.read(routerProvider).go(AuthAppScreen.home.toPath, extra: seed);

    ref.read(walletStateProvider.notifier).connect();

    _updatePrecomputedTables(walletRepository, precomputedTablesPath);
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

  Future<void> _updatePrecomputedTables(
    NativeWalletRepository wallet,
    String path,
  ) async {
    // if full size precomputed tables are not available,
    // we need to generate them and replace the existing ones (default: L1Low)
    if (!await isPrecomputedTablesExists(_getExpectedTableType())) {
      ref
          .read(toastProvider.notifier)
          .showInformation(
            title:
                'Generating the final precomputed tables, this may take a while...',
          );
      wallet
          .updatePrecomputedTables(path, _getExpectedTableType())
          .whenComplete(() async {
            final tableType = await wallet.getPrecomputedTablesType();
            ref
                .read(toastProvider.notifier)
                .showInformation(
                  title: 'Precomputed tables updated: ${tableType.name}',
                );
          });
    }
  }

  Future<bool> isPrecomputedTablesExists(
    PrecomputedTableType precomputedTableType,
  ) async {
    return arePrecomputedTablesAvailable(
      precomputedTablesPath: await _getPrecomputedTablesPath(),
      precomputedTableType: precomputedTableType,
    );
  }

  Future<String> _getPrecomputedTablesPath() async {
    if (kIsWeb) {
      return "";
    } else {
      final dir = await getAppCacheDirPath();
      return "$dir/";
    }
  }

  Future<PrecomputedTableType> _getTableType() async {
    final expectedTableType = _getExpectedTableType();
    if (await isPrecomputedTablesExists(expectedTableType)) {
      return expectedTableType;
    } else {
      return PrecomputedTableType.l1Low;
    }
  }

  PrecomputedTableType _getExpectedTableType() {
    if (isDesktopDevice) {
      return PrecomputedTableType.l1Full;
    } else {
      return PrecomputedTableType.l1Medium;
    }
  }
}
