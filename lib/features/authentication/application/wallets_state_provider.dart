import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';

part 'wallets_state_provider.g.dart';

@riverpod
class Wallets extends _$Wallets {
  late Network _network;
  List<String> _ordering = [];

  @override
  Map<String, String> build() {
    final network =
        ref.watch(settingsProvider.select((value) => value.network));
    _network = network;
    _loadWallets();
    return {};
  }

  Future<Directory> _getWalletsDir() async {
    final walletsPath = await getAppWalletsDirPath();
    return Directory(p.join(walletsPath, _network.name));
  }

  Future<File> _getOrderingFile() async {
    final walletsDir = await _getWalletsDir();
    return File(p.join(walletsDir.path, "ordering.json"));
  }

  Future<void> _loadOrdering() async {
    var file = await _getOrderingFile();
    var exists = await file.exists();

    List<String> ordering = [];
    if (exists) {
      try {
        var data = await file.readAsString();
        ordering = (json.decode(data) as List<dynamic>).cast<String>();
      } catch (e) {
        // skip and default to []
      }
    }

    _ordering = ordering;
  }

  Future<void> _saveWalletsOrdering() async {
    var file = await _getOrderingFile();
    var data = json.encode(_ordering);
    await file.writeAsString(data);
  }

  Future<String> _getWalletAddress(String name) async {
    final walletsDir = await _getWalletsDir();
    var file = File(p.join(walletsDir.path, name, "addr.txt"));
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

  Future<void> _loadWallets() async {
    final walletsDir = await _getWalletsDir();
    var exists = await walletsDir.exists();
    if (!exists) {
      return;
    }

    final files = await walletsDir.list().toList();

    Map<String, String> wallets = {};
    for (var file in files) {
      var stats = await file.stat();
      if (stats.type == FileSystemEntityType.directory) {
        var name = p.basename(file.path);
        var addr = await _getWalletAddress(name);
        wallets[name] = addr;
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
    final walletsDir = await getAppWalletsDirPath();
    final walletPath = p.join(walletsDir, _network.name, name);
    await Directory(walletPath).rename(newName);

    for (var i = 0; i < _ordering.length; i++) {
      if (_ordering[i] == name) {
        _ordering[i] = newName;
        break;
      }
    }

    _applyOrdering();
  }

  Future<void> setWalletAddress(String name, String address) async {
    final walletsDir = await getAppWalletsDirPath();
    final addrPath = p.join(walletsDir, _network.name, name, "addr.txt");
    var file = File(addrPath);
    var exists = await file.exists();

    if (!exists) {
      await file.create();
      await file.writeAsString(address);
    }
  }

  Future<void> deleteWallet(String name) async {
    final walletsDir = await getAppWalletsDirPath();
    final walletPath = p.join(walletsDir, _network.name, name);
    await Directory(walletPath).delete(recursive: true);

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
