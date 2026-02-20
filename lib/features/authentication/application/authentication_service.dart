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

  // Track currently open wallet to prevent lock conflicts
  static NativeWalletRepository? _activeWallet;

  // Prevent concurrent logout operations
  static bool _logoutInProgress = false;

  @override
  AuthenticationState build() {
    _secureStorage = ref.watch(secureStorageProvider);
    return const AuthenticationState.signedOut();
  }

  /// Close the currently active wallet if one exists to release file locks
  Future<void> _closeActiveWalletIfNeeded() async {
    if (_activeWallet != null) {
      try {
        talker.info('Closing active wallet before opening new one');

        // Disconnect from network first
        await ref.read(walletStateProvider.notifier).disconnect();

        // Close wallet to release locks
        await _activeWallet!.close();

        // Dispose FFI resources
        _activeWallet!.dispose();

        talker.info('Active wallet closed successfully');
      } catch (e) {
        talker.error('Error closing active wallet: $e');
      } finally {
        _activeWallet = null;
      }
    }
  }

  Future<void> createWallet(
    String name,
    String password, {
    String? seed,
    String? privateKey,
  }) async {
    // Wait for any logout in progress to prevent race conditions
    while (_logoutInProgress) {
      talker.info('Waiting for logout to complete before creating wallet');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    final loc = ref.read(appLocalizationsProvider);

    // Close any currently open wallet first to release locks
    await _closeActiveWalletIfNeeded();

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
      ref
          .read(toastProvider.notifier)
          .showError(
            title: loc.error_when_creating_wallet,
            description: loc.wallet_name_already_exists,
          );
      return;
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

      talker.info('Wallet created with address: ${walletRepository.address}');
      // save password in secure storage on all platforms except web
      if (!kIsWeb) {
        await _secureStorage.write(key: name, value: password);
      }

      talker.info('Password saved in secure storage for wallet: $name');

      // Track as active wallet
      _activeWallet = walletRepository;

      state = AuthenticationState.signedIn(
        name: name,
        nativeWallet: walletRepository,
      );

      talker.info('State updated to SignedIn for wallet: $name');
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

      talker.info('Navigating to home screen for wallet: $name');
      if (seed == null) {
        final seed = await walletRepository.getSeed();
        ref.read(routerProvider).go(AuthAppScreen.home.toPath, extra: seed);
      } else {
        // if seed is provided, we don't need to show it
        // just navigate to the wallet screen
        ref.read(routerProvider).go(AuthAppScreen.home.toPath);
      }
      talker.info('Connecting wallet state for wallet: $name');
      try {
        ref.read(walletStateProvider.notifier).connect();
      } finally {
        // continue... it's ok if we can't connect
        // the connect() func displays an error message
      }

      talker.info('Updating precomputed tables for wallet: $name');
      _updatePrecomputedTables(walletRepository, precomputedTablesPath);
    }
  }

  Future<void> openWallet(String name, String password) async {
    // Wait for any logout in progress to prevent race conditions
    while (_logoutInProgress) {
      talker.info('Waiting for logout to complete before opening wallet');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    final loc = ref.read(appLocalizationsProvider);
    final settings = ref.read(settingsProvider);

    // Close any currently open wallet first to release locks
    await _closeActiveWalletIfNeeded();

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

      // Track as active wallet
      _activeWallet = walletRepository;

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

    // Track as active wallet
    _activeWallet = walletRepository;

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

  Future<void> logout({bool skipNavigation = false}) async {
    // Prevent concurrent logout operations
    if (_logoutInProgress) {
      talker.warning('Logout already in progress, skipping duplicate call');
      return;
    }

    _logoutInProgress = true;

    try {
      switch (state) {
        case SignedIn(:final nativeWallet):
          talker.info("Logging out: set wallet offline");
          ref.read(walletStateProvider.notifier).disconnect();

          talker.info('Logging out: closing wallet to release locks');
          // Close the wallet first to release database and table locks
          await nativeWallet.close();

          talker.info('Logging out: disposing FFI object');
          // Then dispose the FFI object
          nativeWallet.dispose();

          talker.info('Logging out: clearing active wallet reference');
          _activeWallet = null;

          talker.info('Logging out: setting state to SignedOut');
          state = const AuthenticationState.signedOut();

          if (!skipNavigation) {
            talker.info('Logging out: navigating to open wallet screen');
            ref.read(routerProvider).go(AppScreen.openWallet.toPath);
          }

        case SignedOut():
          talker.info('Logout called but already signed out');
          return;
      }
    } finally {
      _logoutInProgress = false;
    }
  }

  Future<void> _updatePrecomputedTables(
    NativeWalletRepository wallet,
    String path,
  ) async {
    // if full size precomputed tables are not available,
    // we need to generate them and replace the existing ones (default: l1Low)
    if (!await isPrecomputedTablesExists(_getExpectedTableType())) {
      talker.info(
        'Generating the final precomputed tables, this may take a while...',
      );
      ref
          .read(toastProvider.notifier)
          .showInformation(
            title:
                'Generating the final precomputed tables, this may take a while...',
          );
      wallet
          .updatePrecomputedTables(path, _getExpectedTableType())
          .whenComplete(() async {
            talker.info('Precomputed tables updated successfully.');
            ref
                .read(toastProvider.notifier)
                .showInformation(title: 'Precomputed tables updated.');
          });
    }
  }

  Future<bool> isPrecomputedTablesExists(
    PrecomputedTableType precomputedTableType,
  ) async {
    talker.info(
      'Checking if precomputed tables exist for type: $precomputedTableType',
    );
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
      return PrecomputedTableType.l1Low();
    }
  }

  PrecomputedTableType _getExpectedTableType() {
    if (isDesktopDevice) {
      return PrecomputedTableType.l1Full();
    } else if (isMobileDevice) {
      return PrecomputedTableType.custom(BigInt.from(24));
    } else {
      // For web, we can't use more than l1Medium tables due to browser storage & memory limitations,
      // so we use l1Medium as the expected type
      return PrecomputedTableType.l1Medium();
    }
  }
}
