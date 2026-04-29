import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/application/wallets_provider.dart';
import 'package:genesix/features/authentication/domain/biometric_wallet_key.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/authentication/domain/wallet_session_command_result.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/src/generated/rust_bridge/api/precomputed_tables.dart';
import 'package:genesix/src/generated/rust_bridge/api/wallet.dart'
    show updateTables;
import 'package:io/io.dart';
import 'package:localstorage/localstorage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_session_commands_provider.g.dart';

@Riverpod(keepAlive: true)
class WalletSessionCommands extends _$WalletSessionCommands {
  Completer<void>? _activeOperation;

  @override
  void build() {}

  Future<WalletSessionCommandResult> createWallet(
    String name,
    String password, {
    String? seed,
    String? privateKey,
  }) {
    return _runExclusive(() async {
      final loc = ref.read(appLocalizationsProvider);
      final settings = ref.read(settingsProvider);
      final walletPath = await getWalletPath(settings.network, name);
      final walletExists = await _walletExists(walletPath);
      if (walletExists) {
        _emitError(
          title: loc.error_when_creating_wallet,
          description: loc.wallet_name_already_exists,
        );
        return const WalletSessionCommandResult.failure(
          WalletSessionFailure.walletAlreadyExists(),
        );
      }

      await _closeActiveSession();

      final precomputedTablesPath = await _getPrecomputedTablesPath();
      final initialTableType = await _getInitialTableType();
      final expectedTableType = _getExpectedTableType();
      talker.info(
        'Precomputed tables type that will be used: $initialTableType',
      );

      final dbName = walletPath.replaceFirst(localStorageDBPrefix, '');

      try {
        final repository = await _createRepository(
          dbName: dbName,
          password: password,
          network: settings.network,
          precomputedTablesPath: precomputedTablesPath,
          initialTableType: initialTableType,
          seed: seed,
          privateKey: privateKey,
        );

        await _persistOpenedWallet(
          name: name,
          password: password,
          network: settings.network,
          repository: repository,
          writePasswordIfMissingOnly: false,
        );

        ref
            .read(activeWalletSessionProvider.notifier)
            .setSession(WalletSession(name: name, repository: repository));

        _maybeUpgradePrecomputedTables(
          precomputedTablesPath: precomputedTablesPath,
          expectedTableType: expectedTableType,
        );

        final seedToReveal = seed == null ? await repository.getSeed() : null;
        return WalletSessionCommandResult.success(
          name: name,
          seedToReveal: seedToReveal,
        );
      } on AnyhowException catch (error) {
        talker.critical('Creating wallet failed: $error');
        final message = _extractXelisMessage(error);
        _emitError(title: loc.error_when_creating_wallet, description: message);
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.xelis(message: message),
        );
      } catch (error) {
        talker.critical('Creating wallet failed: $error');
        _emitError(
          title: loc.error_when_creating_wallet,
          description: error.toString(),
        );
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.unknown(message: error.toString()),
        );
      }
    });
  }

  Future<WalletSessionCommandResult> openWallet(String name, String password) {
    return _runExclusive(() async {
      final loc = ref.read(appLocalizationsProvider);
      final settings = ref.read(settingsProvider);
      final walletPath = await getWalletPath(settings.network, name);
      final walletExists = await _walletExists(walletPath);
      if (!walletExists) {
        final message = 'This wallet does not exist: $name';
        _emitError(title: loc.error_when_opening_wallet, description: message);
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.walletNotFound(message: message),
        );
      }

      await _closeActiveSession();

      final precomputedTablesPath = await _getPrecomputedTablesPath();
      final initialTableType = await _getInitialTableType();
      final expectedTableType = _getExpectedTableType();
      talker.info(
        'Precomputed tables type that will be used: $initialTableType',
      );

      final dbName = walletPath.replaceFirst(localStorageDBPrefix, '');

      try {
        final repository = await NativeWalletRepository.open(
          dbName,
          password,
          settings.network,
          precomputeTablesPath: precomputedTablesPath,
          precomputedTableType: initialTableType,
        );

        await _persistOpenedWallet(
          name: name,
          password: password,
          network: settings.network,
          repository: repository,
          writePasswordIfMissingOnly: true,
        );

        ref
            .read(activeWalletSessionProvider.notifier)
            .setSession(WalletSession(name: name, repository: repository));

        _maybeUpgradePrecomputedTables(
          precomputedTablesPath: precomputedTablesPath,
          expectedTableType: expectedTableType,
        );

        return WalletSessionCommandResult.success(name: name);
      } on AnyhowException catch (error) {
        talker.critical('Opening wallet failed: $error');
        final message = _extractXelisMessage(error);
        _emitError(title: loc.error_when_opening_wallet, description: message);
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.xelis(message: message),
        );
      } catch (error) {
        talker.critical('Opening wallet failed: $error');
        _emitError(
          title: loc.error_when_opening_wallet,
          description: error.toString(),
        );
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.unknown(message: error.toString()),
        );
      }
    });
  }

  Future<WalletSessionCommandResult> openImportedWallet(
    String sourcePath,
    String walletName,
    String password,
  ) {
    return _runExclusive(() async {
      final loc = ref.read(appLocalizationsProvider);
      final network = ref.read(settingsProvider).network;
      final targetPath = await getWalletPath(network, walletName);
      final walletExists = await _walletExists(targetPath);
      if (walletExists) {
        _emitError(
          title: loc.error_when_opening_wallet,
          description: loc.wallet_already_exists,
        );
        return const WalletSessionCommandResult.failure(
          WalletSessionFailure.walletAlreadyExists(),
        );
      }

      await _closeActiveSession();

      final precomputedTablesPath = await _getPrecomputedTablesPath();
      final initialTableType = await _getInitialTableType();
      final expectedTableType = _getExpectedTableType();
      talker.info(
        'Precomputed tables type that will be used: $initialTableType',
      );

      try {
        await copyPath(sourcePath, targetPath);

        final repository = await NativeWalletRepository.open(
          targetPath,
          password,
          network,
          precomputeTablesPath: precomputedTablesPath,
          precomputedTableType: initialTableType,
        );

        await _persistOpenedWallet(
          name: walletName,
          password: password,
          network: network,
          repository: repository,
          writePasswordIfMissingOnly: true,
        );

        ref
            .read(activeWalletSessionProvider.notifier)
            .setSession(
              WalletSession(name: walletName, repository: repository),
            );

        _maybeUpgradePrecomputedTables(
          precomputedTablesPath: precomputedTablesPath,
          expectedTableType: expectedTableType,
        );

        final seedToReveal = await repository.getSeed();
        return WalletSessionCommandResult.success(
          name: walletName,
          seedToReveal: seedToReveal,
        );
      } on AnyhowException catch (error) {
        talker.critical('Opening imported wallet failed: $error');
        final message = _extractXelisMessage(error);
        _emitError(title: loc.error_when_opening_wallet, description: message);
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.xelis(message: message),
        );
      } catch (error) {
        talker.critical('Opening imported wallet failed: $error');
        _emitError(
          title: loc.error_when_opening_wallet,
          description: error.toString(),
        );
        return WalletSessionCommandResult.failure(
          WalletSessionFailure.unknown(message: error.toString()),
        );
      }
    });
  }

  Future<void> logout() {
    return _runExclusive(() async {
      await _closeActiveSession();
    });
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) async {
    while (_activeOperation != null) {
      await _activeOperation!.future;
    }

    final completer = Completer<void>();
    _activeOperation = completer;
    try {
      return await action();
    } finally {
      _activeOperation = null;
      completer.complete();
    }
  }

  Future<NativeWalletRepository> _createRepository({
    required String dbName,
    required String password,
    required Network network,
    required String precomputedTablesPath,
    required PrecomputedTableType initialTableType,
    String? seed,
    String? privateKey,
  }) {
    if (seed != null) {
      return NativeWalletRepository.recoverFromSeed(
        dbName,
        password,
        network,
        seed: seed,
        precomputeTablesPath: precomputedTablesPath,
        precomputedTableType: initialTableType,
      );
    }
    if (privateKey != null) {
      return NativeWalletRepository.recoverFromPrivateKey(
        dbName,
        password,
        network,
        privateKey: privateKey,
        precomputedTableType: initialTableType,
      );
    }
    return NativeWalletRepository.create(
      dbName,
      password,
      network,
      precomputeTablesPath: precomputedTablesPath,
      precomputedTableType: initialTableType,
    );
  }

  Future<void> _persistOpenedWallet({
    required String name,
    required String password,
    required Network network,
    required NativeWalletRepository repository,
    required bool writePasswordIfMissingOnly,
  }) async {
    await ref
        .read(walletsProvider.notifier)
        .setWalletAddress(name, repository.address);

    if (await _shouldPersistPassword(walletName: name, network: network)) {
      final secureStorage = ref.read(secureStorageProvider);
      final shouldWritePassword =
          !writePasswordIfMissingOnly ||
          !await secureStorage.containsKey(key: name);
      if (shouldWritePassword) {
        await secureStorage.write(key: name, value: password);
      }
    }

    _setLastWalletUsed(network, name);
    await _syncWalletBiometricSetting(name: name, network: network);
  }

  Future<void> _syncWalletBiometricSetting({
    required String name,
    required Network network,
  }) async {
    if (kIsWeb) {
      ref
          .read(settingsProvider.notifier)
          .setActivateBiometricAuth(false, syncWalletStorage: false);
      return;
    }

    final key = biometricWalletKey(network: network, walletName: name);
    final enabled = await ref.read(secureStorageProvider).containsKey(key: key);
    ref
        .read(settingsProvider.notifier)
        .setActivateBiometricAuth(enabled, syncWalletStorage: false);
  }

  Future<bool> _shouldPersistPassword({
    required String walletName,
    required Network network,
  }) async {
    if (kIsWeb) {
      return false;
    }

    final key = biometricWalletKey(network: network, walletName: walletName);
    return ref.read(secureStorageProvider).containsKey(key: key);
  }

  void _setLastWalletUsed(Network network, String name) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    switch (network) {
      case Network.mainnet:
        settingsNotifier.setLastMainnetWalletUsed(name);
      case Network.testnet:
        settingsNotifier.setLastTestnetWalletUsed(name);
      case Network.devnet:
        settingsNotifier.setLastDevnetWalletUsed(name);
      case Network.stagenet:
        settingsNotifier.setLastStagenetWalletUsed(name);
    }
  }

  Future<void> _closeActiveSession() async {
    final activeSession = ref.read(activeWalletSessionProvider);
    if (activeSession == null) {
      ref.read(xswdRequestProvider.notifier).clearRequest();
      ref.invalidate(xswdApplicationsProvider);
      return;
    }

    talker.info('Closing active wallet session for ${activeSession.name}');

    try {
      await ref.read(xswdControllerProvider).stopXSWD();
    } catch (error) {
      talker.warning('Failed to stop XSWD before closing wallet: $error');
    }

    ref.read(xswdRequestProvider.notifier).clearRequest();
    ref.invalidate(xswdApplicationsProvider);

    try {
      await ref.read(walletRuntimeProvider.notifier).prepareForClose();
    } catch (error) {
      talker.warning('Failed to prepare wallet runtime close: $error');
    }

    try {
      await activeSession.repository.close();
    } catch (error) {
      talker.warning('Failed to close wallet repository: $error');
    }

    try {
      await ref.read(walletRuntimeProvider.notifier).clearSession();
    } catch (error) {
      talker.warning('Failed to clear wallet runtime session state: $error');
    } finally {
      ref.read(activeWalletSessionProvider.notifier).clearSession();
      activeSession.repository.dispose();
    }
  }

  Future<bool> _walletExists(String walletPath) async {
    if (kIsWeb) {
      return localStorage.getItem(walletPath) != null;
    }
    return Directory(walletPath).exists();
  }

  void _emitInfo(String title) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.info(title: title));
  }

  void _emitError({String? title, required String description}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.error(title: title, description: description));
  }

  String _extractXelisMessage(AnyhowException error) {
    return error.message.split('\n').first;
  }

  void _maybeUpgradePrecomputedTables({
    required String precomputedTablesPath,
    required PrecomputedTableType expectedTableType,
  }) {
    if (kIsWeb) {
      return;
    }

    unawaited(
      _runPrecomputedTableUpgrade(
        precomputedTablesPath: precomputedTablesPath,
        expectedTableType: expectedTableType,
      ),
    );
  }

  Future<void> _runPrecomputedTableUpgrade({
    required String precomputedTablesPath,
    required PrecomputedTableType expectedTableType,
  }) async {
    final tablesExist = await arePrecomputedTablesAvailable(
      precomputedTablesPath: precomputedTablesPath,
      precomputedTableType: expectedTableType,
    );
    if (tablesExist) {
      return;
    }

    _emitInfo(
      'Generating the final precomputed tables, this may take a while...',
    );
    try {
      await updateTables(
        precomputedTablesPath: precomputedTablesPath,
        precomputedTableType: expectedTableType,
      );
      _emitInfo('Precomputed tables updated.');
    } catch (error) {
      talker.warning('Precomputed table upgrade failed: $error');
    }
  }

  Future<String> _getPrecomputedTablesPath() async {
    if (kIsWeb) {
      return '';
    }
    final dir = await getAppCacheDirPath();
    return '$dir/';
  }

  Future<PrecomputedTableType> _getInitialTableType() async {
    final expectedTableType = _getExpectedTableType();
    final tablesExist = await arePrecomputedTablesAvailable(
      precomputedTablesPath: await _getPrecomputedTablesPath(),
      precomputedTableType: expectedTableType,
    );
    if (tablesExist) {
      return expectedTableType;
    }
    return PrecomputedTableType.l1Low();
  }

  PrecomputedTableType _getExpectedTableType() {
    if (isDesktopDevice) {
      return PrecomputedTableType.l1Full();
    }
    if (isMobileDevice) {
      return PrecomputedTableType.custom(BigInt.from(24));
    }
    return PrecomputedTableType.l1Medium();
  }
}
