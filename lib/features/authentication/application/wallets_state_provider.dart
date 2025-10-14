import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:genesix/features/authentication/domain/wallets_state.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:localstorage/localstorage.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/utils/utils.dart';

part 'wallets_state_provider.g.dart';

@riverpod
class Wallets extends _$Wallets {
  final String _addressFileName = "addr.txt";
  late Network _network;

  @override
  Future<WalletsState> build() async {
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    _network = network;

    final lastWalletsUsed = ref.watch(
      settingsProvider.select((state) => state.lastWalletsUsed),
    );

    final wallets = await _loadWallets();

    return WalletsState(wallets: wallets, lastWalletsUsed: lastWalletsUsed);
  }

  Future<String> _getWalletDirPath() async {
    final walletsPath = await getAppWalletsDirPath();
    return p.join(walletsPath, _network.name);
  }

  Future<Directory> _getWalletsDir() async {
    final walletsPath = await _getWalletDirPath();
    return Directory(walletsPath);
  }

  Future<String> _getWalletAddressPath(String name) async {
    final walletsDir = await _getWalletsDir();
    return p.join(walletsDir.path, name, _addressFileName);
  }

  Future<String> _getWalletAddress(String name) async {
    var walletAddressPath = await _getWalletAddressPath(name);

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

  Future<Map<String, String>> _loadWallets() async {
    Map<String, String> wallets = {};

    if (kIsWeb) {
      final walletsPath = await _getWalletDirPath();

      // not using SharedPreferences because it's loading all keys & values in cache
      // it's also using a prefix and we need to use allowList -_-

      for (int i = 0; i < localStorage.length; i++) {
        var key = localStorage.key(i)!;
        if (key.startsWith(walletsPath) && !key.endsWith(_addressFileName)) {
          var name = p.basename(key);

          var addr = await _getWalletAddress(name);
          wallets[name] = addr;
        }
      }
    } else {
      final walletsDir = await _getWalletsDir();
      var exists = await walletsDir.exists();
      if (!exists) {
        return wallets;
      }

      final files = await walletsDir.list().toList();
      for (var file in files) {
        var stats = await file.stat();
        if (stats.type == FileSystemEntityType.directory) {
          var name = p.basename(file.path);
          var addr = await _getWalletAddress(name);
          wallets[name] = addr;
        }
      }
    }

    return wallets;
  }

  Future<void> renameWallet(String name, String newName) async {
    final walletsPath = await _getWalletDirPath();
    final walletPath = p.join(walletsPath, name);
    final newWalletPath = p.join(walletsPath, newName);
    final loc = ref.read(appLocalizationsProvider);

    if (kIsWeb) {
      final newPath = localStorage.getItem(newWalletPath);
      if (newPath != null) {
        throw loc.wallet_name_already_exists;
      }
    } else {
      final newDir = Directory(newWalletPath);
      final exists = await newDir.exists();
      if (exists) {
        throw loc.wallet_name_already_exists;
      }
    }

    if (Platform.isWindows) {
      // On Windows, we need to logout before renaming the wallet
      // because the wallet file is locked by the process.
      // Otherwise, we get an "Access is denied" error.
      // TODO: test for web
      final auth = ref.read(authenticationProvider.notifier);
      await auth.logout();
    }

    if (kIsWeb) {
      final wallet = localStorage.getItem(walletPath);
      localStorage.setItem(newWalletPath, wallet!);
      localStorage.removeItem(walletPath);
    } else {
      await Directory(walletPath).rename(newWalletPath);
    }

    final settingsNotifier = ref.read(settingsProvider.notifier);
    switch (_network) {
      case Network.mainnet:
        settingsNotifier.setLastMainnetWalletUsed(newName);
      case Network.testnet:
        settingsNotifier.setLastTestnetWalletUsed(newName);
      case Network.devnet:
        settingsNotifier.setLastDevnetWalletUsed(newName);
      case Network.stagenet:
        settingsNotifier.setLastStagenetWalletUsed(newName);
    }
  }

  Future<void> setWalletAddress(String name, String address) async {
    var walletAddressPath = await _getWalletAddressPath(name);

    if (kIsWeb) {
      localStorage.setItem(walletAddressPath, address);
    } else {
      var file = File(walletAddressPath);
      var exists = await file.exists();

      if (!exists) {
        await file.create();
        await file.writeAsString(address);
      }
    }
  }

  Future<void> deleteWallet(String name) async {
    final walletsPath = await _getWalletDirPath();
    final walletPath = p.join(walletsPath, name);

    final auth = ref.read(authenticationProvider.notifier);
    await auth.logout();

    if (kIsWeb) {
      localStorage.removeItem(walletPath);
    } else {
      await Directory(walletPath).delete(recursive: true);
    }
  }
}
