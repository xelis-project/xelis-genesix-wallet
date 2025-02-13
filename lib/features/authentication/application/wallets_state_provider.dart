import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/src/generated/rust_bridge/api/network.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/utils/utils.dart';

part 'wallets_state_provider.g.dart';

@riverpod
class Wallets extends _$Wallets {
  final String _addressFileName = "addr.txt";
  final String _orderingFileName = "ordering.json";
  late Network _network;
  List<String> _ordering = [];

  @override
  Map<String, String> build() {
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    _network = network;
    _loadWallets();
    return {};
  }

  Future<String> _getWalletDirPath() async {
    final walletsPath = await getAppWalletsDirPath();
    return p.join(walletsPath, _network.name);
  }

  Future<Directory> _getWalletsDir() async {
    final walletsPath = await _getWalletDirPath();
    return Directory(walletsPath);
  }

  Future<String> _getOrderingFilePath() async {
    final walletsDir = await _getWalletsDir();
    return p.join(walletsDir.path, _orderingFileName);
  }

  Future<void> _loadOrdering() async {
    var orderingPath = await _getOrderingFilePath();
    List<String> ordering = [];

    String? data;

    if (kIsWeb) {
      data = localStorage.getItem(orderingPath);
    } else {
      var file = File(orderingPath);
      var exists = await file.exists();

      if (exists) {
        data = await file.readAsString();
      }
    }

    if (data != null) {
      try {
        ordering = (json.decode(data) as List<dynamic>).cast<String>();
      } catch (e) {
        // skip and default to []
      }
    }

    _ordering = ordering;
  }

  Future<void> _saveWalletsOrdering() async {
    var orderingPath = await _getOrderingFilePath();

    if (kIsWeb) {
      var data = json.encode(_ordering);
      localStorage.setItem(orderingPath, data);
    } else {
      var file = File(orderingPath);
      var data = json.encode(_ordering);
      await file.writeAsString(data);
    }
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

  Future<void> _loadWallets() async {
    Map<String, String> wallets = {};

    if (kIsWeb) {
      final walletsPath = await _getWalletDirPath();

      // not using SharedPreferences because it's loading all keys & values in cache
      // it's also using a prefix and we need to use allowList -_-

      for (int i = 0; i < localStorage.length; i++) {
        var key = localStorage.key(i)!;
        if (key.startsWith(walletsPath) &&
            !key.endsWith(_addressFileName) &&
            !key.endsWith(_orderingFileName)) {
          var name = p.basename(key);

          var addr = await _getWalletAddress(name);
          wallets[name] = addr;
        }
      }
    } else {
      final walletsDir = await _getWalletsDir();
      var exists = await walletsDir.exists();
      if (!exists) {
        return;
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

    state = wallets;
    await _loadOrdering();
    _applyOrdering();
  }

  void _applyOrdering() {
    Map<String, String> orderedWallets = {};

    for (var name in state.keys) {
      if (!_ordering.contains(name)) {
        _ordering.add(name);
      }
    }

    List<String> toRemove = [];
    for (var name in _ordering) {
      if (state.containsKey(name)) {
        orderedWallets[name] = state[name]!;
      } else {
        toRemove.add(name);
      }
    }

    _ordering.removeWhere((element) => toRemove.contains(element));

    state = orderedWallets;
    _saveWalletsOrdering();
  }

  Future<void> renameWallet(String name, String newName) async {
    final walletsPath = await _getWalletDirPath();
    final walletPath = p.join(walletsPath, name);
    final newWalletPath = p.join(walletsPath, newName);

    if (kIsWeb) {
      final newPath = localStorage.getItem(newWalletPath);
      if (newPath != null) {
        throw 'A wallet with this name already exists.';
      }
    } else {
      final newDir = Directory(newWalletPath);
      final exists = await newDir.exists();
      if (exists) {
        throw 'A wallet with this name already exists.';
      }
    }

    final auth = ref.read(authenticationProvider.notifier);
    await auth.logout();

    if (kIsWeb) {
      final wallet = localStorage.getItem(walletPath);
      localStorage.setItem(newWalletPath, wallet!);
    } else {
      await Directory(walletPath).rename(newWalletPath);
    }

    for (var i = 0; i < _ordering.length; i++) {
      if (_ordering[i] == name) {
        _ordering[i] = newName;
        break;
      }
    }

    _applyOrdering();
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

    _ordering.remove(name);
    _applyOrdering();
  }

  Future<void> orderWallet(String name, int order) async {
    if (order >= 0 && order < _ordering.length) {
      _ordering.removeWhere((e) => e == name);
      _ordering.insert(order, name);

      _applyOrdering();
    }
  }
}
