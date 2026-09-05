import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/biometric_wallet_key.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/authentication/domain/wallets_state.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:localstorage/localstorage.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'wallets_provider.g.dart';

@riverpod
class Wallets extends _$Wallets {
  final String _addressFileName = "addr.txt";
  late XelisNetwork _network;

  @override
  Future<WalletsState> build() async {
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    _network = network;

    final lastWalletsUsed = ref.watch(
      settingsProvider.select((state) => state.lastWalletsUsed),
    );

    final wallets = await _loadWallets(network);

    return WalletsState(wallets: wallets, lastWalletsUsed: lastWalletsUsed);
  }

  Future<String> _getWalletDirPath(XelisNetwork network) async {
    final walletsPath = await getAppWalletsDirPath();
    return p.join(walletsPath, network.name);
  }

  Future<Directory> _getWalletsDir(XelisNetwork network) async {
    final walletsPath = await _getWalletDirPath(network);
    return Directory(walletsPath);
  }

  Future<String> _getWalletAddressPath(
    XelisNetwork network,
    String name,
  ) async {
    final walletPath = await getWalletPath(network, name);
    return p.join(walletPath, _addressFileName);
  }

  Future<String> _getWalletAddress(XelisNetwork network, String name) async {
    var walletAddressPath = await _getWalletAddressPath(network, name);

    if (kIsWeb) {
      var addr = localStorage.getItem(walletAddressPath);
      return addr ?? "";
    } else {
      var file = File(walletAddressPath);
      var exists = await file.exists();
      if (exists) {
        try {
          return await file.readAsString();
        } catch (e) {
          return "";
        }
      } else {
        return "";
      }
    }
  }

  Future<Map<String, String>> _loadWallets(XelisNetwork network) async {
    Map<String, String> wallets = {};

    if (kIsWeb) {
      final walletsPath = await _getWalletDirPath(network);

      // not using SharedPreferences because it's loading all keys & values in cache
      // it's also using a prefix and we need to use allowList -_-

      for (int i = 0; i < localStorage.length; i++) {
        final key = localStorage.key(i);
        if (key == null || !p.isWithin(walletsPath, key)) continue;

        final name = p.relative(key, from: walletsPath);
        if (!isValidWalletName(name)) continue;

        final walletPath = await getWalletPath(network, name);
        if (p.normalize(key) != walletPath) continue;

        final addr = await _getWalletAddress(network, name);
        wallets[name] = addr;
      }
    } else {
      final walletsDir = await _getWalletsDir(network);
      var exists = await walletsDir.exists();
      if (!exists) {
        return wallets;
      }

      final files = await walletsDir.list().toList();
      for (var file in files) {
        final type = await FileSystemEntity.type(file.path, followLinks: false);
        if (type == FileSystemEntityType.directory) {
          final name = p.basename(file.path);
          if (!isValidWalletName(name)) continue;

          final addr = await _getWalletAddress(network, name);
          wallets[name] = addr;
        }
      }
    }

    return wallets;
  }

  Future<bool> renameWallet(String name, String newName) async {
    final network = _network;
    final walletPath = await getWalletPath(network, name);
    final newWalletPath = await getWalletPath(network, newName);
    final walletAddressPath = await _getWalletAddressPath(network, name);
    final newWalletAddressPath = await _getWalletAddressPath(network, newName);
    final loc = ref.read(appLocalizationsProvider);
    final activeSession = ref.read(activeWalletSessionProvider);

    if (kIsWeb) {
      final newPath = localStorage.getItem(newWalletPath);
      if (newPath != null) {
        throw loc.wallet_name_already_exists;
      }
    } else {
      await _requireDirectWalletDirectory(walletPath);
      final newPathType = await FileSystemEntity.type(
        newWalletPath,
        followLinks: false,
      );
      if (newPathType != FileSystemEntityType.notFound) {
        throw loc.wallet_name_already_exists;
      }
    }

    if (!kIsWeb && Platform.isWindows) {
      if (isSessionForWalletTarget(activeSession, network, name)) {
        if (!isSameWalletSession(
          ref.read(activeWalletSessionProvider),
          activeSession,
        )) {
          throw StateError('The active wallet session changed.');
        }
        final closeFailure = await ref
            .read(walletSessionCommandsProvider.notifier)
            .logout();
        if (closeFailure != null) return false;
      }
    }

    if (kIsWeb) {
      final wallet = localStorage.getItem(walletPath);
      localStorage.setItem(newWalletPath, wallet!);
      localStorage.removeItem(walletPath);

      final address = localStorage.getItem(walletAddressPath);
      localStorage.removeItem(newWalletAddressPath);
      if (address != null) {
        localStorage.setItem(newWalletAddressPath, address);
      }
      localStorage.removeItem(walletAddressPath);
    } else {
      await _requireDirectWalletDirectory(walletPath);
      await Directory(walletPath).rename(newWalletPath);

      final secureStorage = ref.read(secureStorageProvider);
      final password = await _readStoredWalletPassword(
        name: name,
        network: network,
      );
      final oldBiometricKey = biometricWalletKey(
        network: network,
        walletName: name,
      );
      final newBiometricKey = biometricWalletKey(
        network: network,
        walletName: newName,
      );
      final biometricEnabled = await secureStorage.containsKey(
        key: oldBiometricKey,
      );
      if (biometricEnabled) {
        await secureStorage.write(key: newBiometricKey, value: '1');
        await secureStorage.delete(key: oldBiometricKey);
        if (password != null) {
          await secureStorage.write(
            key: walletPasswordKey(network: network, walletName: newName),
            value: password,
          );
        }
      }
      await secureStorage.delete(
        key: walletPasswordKey(network: network, walletName: name),
      );
      await _deleteLegacyPasswordIfUnused(name: name, currentNetwork: network);
    }

    final settingsNotifier = ref.read(settingsProvider.notifier);
    switch (network) {
      case XelisNetwork.mainnet:
        settingsNotifier.setLastMainnetWalletUsed(newName);
      case XelisNetwork.testnet:
        settingsNotifier.setLastTestnetWalletUsed(newName);
      case XelisNetwork.devnet:
        settingsNotifier.setLastDevnetWalletUsed(newName);
      case XelisNetwork.stagenet:
        settingsNotifier.setLastStagenetWalletUsed(newName);
    }

    final currentSession = ref.read(activeWalletSessionProvider);
    if (isSessionForWalletTarget(activeSession, network, name) &&
        isSameWalletSession(currentSession, activeSession)) {
      ref
          .read(activeWalletSessionProvider.notifier)
          .setSession(
            WalletSession(
              name: newName,
              repository: currentSession!.repository,
            ),
          );
    }
    return true;
  }

  Future<void> setWalletAddress(String name, String address) async {
    final network = _network;
    var walletAddressPath = await _getWalletAddressPath(network, name);

    if (kIsWeb) {
      localStorage.setItem(walletAddressPath, address);
    } else {
      await _requireDirectWalletDirectory(await getWalletPath(network, name));
      var file = File(walletAddressPath);
      var exists = await file.exists();

      if (!exists) {
        await file.create();
        await file.writeAsString(address);
      }
    }
  }

  Future<bool> deleteWallet(String name) async {
    final network = _network;
    final walletPath = await getWalletPath(network, name);
    final walletAddressPath = await _getWalletAddressPath(network, name);

    final activeSession = ref.read(activeWalletSessionProvider);
    if (!kIsWeb) {
      await _requireDirectWalletDirectory(walletPath);
    }
    if (isSessionForWalletTarget(activeSession, network, name)) {
      if (!isSameWalletSession(
        ref.read(activeWalletSessionProvider),
        activeSession,
      )) {
        throw StateError('The active wallet session changed.');
      }
      final closeFailure = await ref
          .read(walletSessionCommandsProvider.notifier)
          .logout();
      if (closeFailure != null) return false;
    }

    if (kIsWeb) {
      localStorage.removeItem(walletPath);
      localStorage.removeItem(walletAddressPath);
    } else {
      await _requireDirectWalletDirectory(walletPath);
      await Directory(walletPath).delete(recursive: true);

      final secureStorage = ref.read(secureStorageProvider);
      final biometricKey = biometricWalletKey(
        network: network,
        walletName: name,
      );
      await secureStorage.delete(key: biometricKey);
      await secureStorage.delete(
        key: walletPasswordKey(network: network, walletName: name),
      );
      await _deleteLegacyPasswordIfUnused(name: name, currentNetwork: network);
    }
    return true;
  }

  Future<void> _requireDirectWalletDirectory(String walletPath) async {
    final type = await FileSystemEntity.type(walletPath, followLinks: false);
    if (type != FileSystemEntityType.directory) {
      throw const UnsafeWalletPathException();
    }
  }

  Future<String?> _readStoredWalletPassword({
    required String name,
    required XelisNetwork network,
  }) async {
    final secureStorage = ref.read(secureStorageProvider);
    final password = await secureStorage.read(
      key: walletPasswordKey(network: network, walletName: name),
    );
    return password ??
        secureStorage.read(key: legacyWalletPasswordKey(walletName: name));
  }

  Future<void> _deleteLegacyPasswordIfUnused({
    required String name,
    required XelisNetwork currentNetwork,
  }) async {
    final secureStorage = ref.read(secureStorageProvider);
    for (final network in XelisNetwork.values) {
      if (network == currentNetwork) {
        continue;
      }
      final hasOtherBiometricWallet = await secureStorage.containsKey(
        key: biometricWalletKey(network: network, walletName: name),
      );
      if (hasOtherBiometricWallet) {
        return;
      }
    }

    await secureStorage.delete(key: legacyWalletPasswordKey(walletName: name));
  }
}

bool isSessionForWalletTarget(
  WalletSession? session,
  XelisNetwork network,
  String name,
) {
  return session != null && session.name == name && session.network == network;
}

bool isSameWalletSession(WalletSession? current, WalletSession? captured) {
  if (current == null || captured == null) return current == captured;
  return current.name == captured.name &&
      current.network == captured.network &&
      identical(current.repository, captured.repository);
}
