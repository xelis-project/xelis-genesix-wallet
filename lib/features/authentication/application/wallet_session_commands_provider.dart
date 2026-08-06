import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:genesix/features/wallet/application/xswd_lifecycle_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
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
      if (hasAmbiguousWalletRecoverySources(
        seed: seed,
        privateKey: privateKey,
      )) {
        final failure = recordAppFailure(
          ArgumentError('Seed and private key are mutually exclusive.'),
          StackTrace.current,
          operation: 'wallet.create',
          applicationCode: 'wallet_recovery_source_ambiguous',
          applicationCategory: AppFailureCategory.invalidInput,
        );
        _emitFailure(title: loc.error_when_creating_wallet, failure: failure);
        return _commandFailure(failure);
      }
      final settings = ref.read(settingsProvider);
      final walletPathResult = await _resolveWalletPath(
        network: settings.network,
        name: name,
      );
      final walletPath = walletPathResult.path;
      if (walletPath == null) {
        _emitFailure(
          title: loc.error_when_creating_wallet,
          failure: walletPathResult.failure!,
        );
        return const WalletSessionCommandResult.failure(
          WalletSessionFailure.invalidWalletFolder(),
        );
      }
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

      final closeFailure = await _closeActiveSession();
      if (closeFailure != null) {
        _emitFailure(
          title: loc.error_when_creating_wallet,
          failure: closeFailure,
        );
        return _commandFailure(closeFailure);
      }

      final precomputedTablesPath = await _getPrecomputedTablesPath();
      final initialTableType = await _getInitialTableType();
      final expectedTableType = _getExpectedTableType();
      talker.info(
        'Precomputed tables type that will be used: $initialTableType',
      );

      final dbName = walletPath.replaceFirst(localStorageDBPrefix, '');

      NativeWalletRepository? repository;
      try {
        repository = await _createRepository(
          dbName: dbName,
          password: password,
          network: settings.network,
          precomputedTablesPath: precomputedTablesPath,
          initialTableType: initialTableType,
          seed: seed,
          privateKey: privateKey,
        );
        final seedToReveal = seed == null ? await repository.getSeed() : null;

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
        repository = null;

        _maybeUpgradePrecomputedTables(
          precomputedTablesPath: precomputedTablesPath,
          expectedTableType: expectedTableType,
        );

        return WalletSessionCommandResult.success(
          name: name,
          seedToReveal: seedToReveal,
        );
      } catch (error, stackTrace) {
        await _disposeUnattachedRepository(repository);
        final failure = recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.create',
          applicationCode: 'wallet_create_failed',
          contextBuilder: () =>
              'network=${settings.network.name} path=$walletPath',
        );
        _emitFailure(title: loc.error_when_creating_wallet, failure: failure);
        return _commandFailure(failure);
      }
    });
  }

  Future<WalletSessionCommandResult> openWallet(String name, String password) {
    return _runExclusive(() async {
      final loc = ref.read(appLocalizationsProvider);
      final settings = ref.read(settingsProvider);
      final walletPathResult = await _resolveWalletPath(
        network: settings.network,
        name: name,
      );
      final walletPath = walletPathResult.path;
      if (walletPath == null) {
        _emitFailure(
          title: loc.error_when_opening_wallet,
          failure: walletPathResult.failure!,
        );
        return const WalletSessionCommandResult.failure(
          WalletSessionFailure.invalidWalletFolder(),
        );
      }
      final walletExists = await _walletExists(walletPath);
      if (!walletExists) {
        final message = 'This wallet does not exist: $name';
        _emitError(title: loc.error_when_opening_wallet, description: message);
        return const WalletSessionCommandResult.failure(
          WalletSessionFailure.walletNotFound(),
        );
      }

      final closeFailure = await _closeActiveSession();
      if (closeFailure != null) {
        _emitFailure(
          title: loc.error_when_opening_wallet,
          failure: closeFailure,
        );
        return _commandFailure(closeFailure);
      }

      final precomputedTablesPath = await _getPrecomputedTablesPath();
      final initialTableType = await _getInitialTableType();
      final expectedTableType = _getExpectedTableType();
      talker.info(
        'Precomputed tables type that will be used: $initialTableType',
      );

      final dbName = walletPath.replaceFirst(localStorageDBPrefix, '');

      NativeWalletRepository? repository;
      try {
        repository = await NativeWalletRepository.open(
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
        repository = null;

        _maybeUpgradePrecomputedTables(
          precomputedTablesPath: precomputedTablesPath,
          expectedTableType: expectedTableType,
        );

        return WalletSessionCommandResult.success(name: name);
      } catch (error, stackTrace) {
        await _disposeUnattachedRepository(repository);
        final failure = recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.open',
          applicationCode: 'wallet_open_failed',
          contextBuilder: () =>
              'network=${settings.network.name} path=$walletPath',
        );
        _emitFailure(title: loc.error_when_opening_wallet, failure: failure);
        return _commandFailure(failure);
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
      final targetPathResult = await _resolveWalletPath(
        network: network,
        name: walletName,
      );
      final targetPath = targetPathResult.path;
      if (targetPath == null) {
        _emitFailure(
          title: loc.error_when_opening_wallet,
          failure: targetPathResult.failure!,
        );
        return const WalletSessionCommandResult.failure(
          WalletSessionFailure.invalidWalletFolder(),
        );
      }
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

      final closeFailure = await _closeActiveSession();
      if (closeFailure != null) {
        _emitFailure(
          title: loc.error_when_opening_wallet,
          failure: closeFailure,
        );
        return _commandFailure(closeFailure);
      }

      final precomputedTablesPath = await _getPrecomputedTablesPath();
      final initialTableType = await _getInitialTableType();
      final expectedTableType = _getExpectedTableType();
      talker.info(
        'Precomputed tables type that will be used: $initialTableType',
      );

      NativeWalletRepository? repository;
      try {
        await copyPath(sourcePath, targetPath);

        repository = await NativeWalletRepository.open(
          targetPath,
          password,
          network,
          precomputeTablesPath: precomputedTablesPath,
          precomputedTableType: initialTableType,
        );
        final seedToReveal = await repository.getSeed();

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
        repository = null;

        _maybeUpgradePrecomputedTables(
          precomputedTablesPath: precomputedTablesPath,
          expectedTableType: expectedTableType,
        );

        return WalletSessionCommandResult.success(
          name: walletName,
          seedToReveal: seedToReveal,
        );
      } catch (error, stackTrace) {
        await _disposeUnattachedRepository(repository);
        final failure = recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.import.open',
          applicationCode: 'wallet_import_open_failed',
          contextBuilder: () =>
              'network=${network.name} targetPath=$targetPath',
        );
        _emitFailure(title: loc.error_when_opening_wallet, failure: failure);
        return _commandFailure(failure);
      }
    });
  }

  Future<AppFailure?> logout() {
    return _runExclusive(() async {
      final failure = await _closeActiveSession();
      if (failure != null) {
        _emitFailure(failure: failure);
      }
      return failure;
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

  Future<void> _disposeUnattachedRepository(
    NativeWalletRepository? repository,
  ) async {
    if (repository == null) {
      return;
    }

    try {
      await repository.close();
    } catch (error, stackTrace) {
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.repository.unattached.close',
        applicationCode: 'wallet_unattached_close_failed',
        contextBuilder: () => 'network=${repository.network.name}',
      );
    } finally {
      try {
        repository.dispose();
      } catch (error, stackTrace) {
        recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.repository.unattached.dispose',
          applicationCode: 'wallet_unattached_dispose_failed',
          contextBuilder: () => 'network=${repository.network.name}',
        );
      }
    }
  }

  Future<({AppFailure? failure, String? path})> _resolveWalletPath({
    required XelisNetwork network,
    required String name,
  }) async {
    try {
      return (path: await getWalletPath(network, name), failure: null);
    } catch (error, stackTrace) {
      final invalidName = error is InvalidWalletNameException;
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.path.resolve',
        applicationCode: invalidName
            ? 'wallet_name_invalid'
            : 'wallet_path_resolution_failed',
        applicationCategory: invalidName
            ? AppFailureCategory.invalidInput
            : AppFailureCategory.storageFailure,
        contextBuilder: () => 'network=${network.name}',
      );
      return (path: null, failure: failure);
    }
  }

  WalletSessionCommandResult _commandFailure(AppFailure failure) {
    final sessionFailure = failure.source == 'genesix'
        ? const WalletSessionFailure.unknown()
        : const WalletSessionFailure.xelis();
    return WalletSessionCommandResult.failure(sessionFailure);
  }

  Future<NativeWalletRepository> _createRepository({
    required String dbName,
    required String password,
    required XelisNetwork network,
    required String precomputedTablesPath,
    required XelisPrecomputedTableType initialTableType,
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
        precomputeTablesPath: precomputedTablesPath,
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
    required XelisNetwork network,
    required NativeWalletRepository repository,
    required bool writePasswordIfMissingOnly,
  }) async {
    await ref
        .read(walletsProvider.notifier)
        .setWalletAddress(name, repository.address);

    if (await _shouldPersistPassword(walletName: name, network: network)) {
      final secureStorage = ref.read(secureStorageProvider);
      final passwordKey = walletPasswordKey(network: network, walletName: name);
      final shouldWritePassword =
          !writePasswordIfMissingOnly ||
          !await secureStorage.containsKey(key: passwordKey);
      if (shouldWritePassword) {
        await secureStorage.write(key: passwordKey, value: password);
      }
    }

    _setLastWalletUsed(network, name);
    await _syncWalletBiometricSetting(name: name, network: network);
  }

  Future<void> _syncWalletBiometricSetting({
    required String name,
    required XelisNetwork network,
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
    required XelisNetwork network,
  }) async {
    if (kIsWeb) {
      return false;
    }

    final key = biometricWalletKey(network: network, walletName: walletName);
    return ref.read(secureStorageProvider).containsKey(key: key);
  }

  void _setLastWalletUsed(XelisNetwork network, String name) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    switch (network) {
      case XelisNetwork.mainnet:
        settingsNotifier.setLastMainnetWalletUsed(name);
      case XelisNetwork.testnet:
        settingsNotifier.setLastTestnetWalletUsed(name);
      case XelisNetwork.devnet:
        settingsNotifier.setLastDevnetWalletUsed(name);
      case XelisNetwork.stagenet:
        settingsNotifier.setLastStagenetWalletUsed(name);
    }
  }

  Future<AppFailure?> _closeActiveSession() async {
    final activeSession = ref.read(activeWalletSessionProvider);
    if (activeSession == null) {
      ref.read(xswdRequestProvider.notifier).clearRequest();
      ref.invalidate(xswdApplicationsProvider);
      return null;
    }

    logDiagnostic(
      () => 'Closing active wallet session: name=${activeSession.name}',
    );

    try {
      await ref.read(xswdLifecycleProvider.notifier).stop();
    } catch (error, stackTrace) {
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.session.xswd.stop',
        applicationCode: 'wallet_xswd_stop_failed',
      );
    }

    ref.read(xswdRequestProvider.notifier).clearRequest();
    ref.invalidate(xswdApplicationsProvider);

    try {
      await ref.read(walletRuntimeProvider.notifier).prepareForClose();
    } catch (error, stackTrace) {
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.session.runtime.prepare_close',
        applicationCode: 'wallet_runtime_prepare_close_failed',
      );
    }

    AppFailure? terminalFailure;
    try {
      await activeSession.repository.close();
    } catch (error, stackTrace) {
      terminalFailure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.session.repository.close',
        applicationCode: 'wallet_close_failed',
        contextBuilder: () =>
            'network=${activeSession.repository.network.name}',
      );
    }

    try {
      await ref.read(walletRuntimeProvider.notifier).clearSession();
    } catch (error, stackTrace) {
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.session.runtime.clear',
        applicationCode: 'wallet_runtime_clear_failed',
      );
    } finally {
      ref.read(activeWalletSessionProvider.notifier).clearSession();
      try {
        activeSession.repository.dispose();
      } catch (error, stackTrace) {
        terminalFailure ??= recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.session.repository.dispose',
          applicationCode: 'wallet_dispose_failed',
          contextBuilder: () =>
              'network=${activeSession.repository.network.name}',
        );
      }
    }
    return terminalFailure;
  }

  Future<bool> _walletExists(String walletPath) async {
    if (kIsWeb) {
      return localStorage.getItem(walletPath) != null;
    }
    final type = await FileSystemEntity.type(walletPath, followLinks: false);
    return type == FileSystemEntityType.directory;
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

  void _emitFailure({String? title, required AppFailure failure}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.failure(title: title, failure: failure));
  }

  void _maybeUpgradePrecomputedTables({
    required String precomputedTablesPath,
    required XelisPrecomputedTableType expectedTableType,
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
    required XelisPrecomputedTableType expectedTableType,
  }) async {
    final tablesExist = await XelisWalletFlutter.hasPrecomputedTables(
      path: precomputedTablesPath,
      type: expectedTableType,
    );
    if (tablesExist) {
      return;
    }

    _emitInfo(
      'Generating the final precomputed tables, this may take a while...',
    );
    try {
      await XelisWalletFlutter.updatePrecomputedTables(
        path: precomputedTablesPath,
        type: expectedTableType,
      );
      _emitInfo('Precomputed tables updated.');
    } catch (error) {
      logDiagnosticError('wallet.precomputed_tables.upgrade', error);
    }
  }

  Future<String> _getPrecomputedTablesPath() async {
    if (kIsWeb) {
      return '';
    }
    final dir = await getAppCacheDirPath();
    return '$dir/';
  }

  Future<XelisPrecomputedTableType> _getInitialTableType() async {
    final expectedTableType = _getExpectedTableType();
    final tablesExist = await XelisWalletFlutter.hasPrecomputedTables(
      path: await _getPrecomputedTablesPath(),
      type: expectedTableType,
    );
    if (tablesExist) {
      return expectedTableType;
    }
    return const XelisPrecomputedTableType.l1Low();
  }

  XelisPrecomputedTableType _getExpectedTableType() {
    if (isDesktopDevice) {
      return const XelisPrecomputedTableType.l1Full();
    }
    if (isMobileDevice) {
      return const XelisPrecomputedTableType.custom(24);
    }
    return const XelisPrecomputedTableType.l1Medium();
  }
}

bool hasAmbiguousWalletRecoverySources({
  required String? seed,
  required String? privateKey,
}) {
  return seed != null && privateKey != null;
}
