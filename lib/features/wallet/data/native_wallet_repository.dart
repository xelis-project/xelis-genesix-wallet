import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/xelis_network.dart';
import 'package:xelis_mobile_wallet/src/rust/api/wallet.dart';

class NativeWalletRepository {
  NativeWalletRepository._internal(this._xelisWallet);

  final XelisWallet _xelisWallet;

  static Future<NativeWalletRepository> create(
      String name, String pwd, Network network) async {
    await setNetwork(network);
    final dir = await getApplicationDocumentsDirectory();
    final xelisWallet =
        await createXelisWallet(name: '${dir.path}/$name', password: pwd);
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> recover(
      String name, String pwd, Network network,
      {required String seed}) async {
    await setNetwork(network);
    final dir = await getApplicationDocumentsDirectory();
    final xelisWallet = await createXelisWallet(
        name: '${dir.path}/$name', password: pwd, seed: seed);
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> open(
      String name, String pwd, Network network) async {
    await setNetwork(network);
    final dir = await getApplicationDocumentsDirectory();
    final xelisWallet =
        await openXelisWallet(name: '${dir.path}/$name', password: pwd);
    return NativeWalletRepository._internal(xelisWallet);
  }

  void dispose() {
    _xelisWallet.dispose();
  }

  String get humanReadableAddress => _xelisWallet.getAddressStr();

  Future<int> get nonce => _xelisWallet.getNonce();

  Future<bool> get isOnline => _xelisWallet.isOnline();

  Future<void> changePassword(
      {required String oldPassword, required String newPassword}) async {
    return _xelisWallet.changePassword(
        oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<String> getSeed({required String password, int? languageIndex}) async {
    return _xelisWallet.getSeed(
        password: password, languageIndex: languageIndex);
  }

  Future<String> getXelisBalance() async {
    return _xelisWallet.getXelisBalance();
  }

  Future<Map<String, String>> getAssetBalances() async {
    return _xelisWallet.getAssetBalances();
  }

  Future<void> rescan({required int topoHeight}) async {
    return _xelisWallet.rescan(topoheight: topoHeight);
  }

  Future<String> transfer(
      {required double amount,
      required String address,
      String? assetHash}) async {
    return _xelisWallet.transfer(
        floatAmount: amount, strAddress: address, assetHash: assetHash);
  }

  Future<List<String>> history({required int page}) async {
    // TODO deserialize history entry
    return _xelisWallet.history(requestedPage: page);
  }

  Future<void> setOnline({required String daemonAddress}) async {
    try {
      await _xelisWallet.onlineMode(daemonAddress: daemonAddress);
    } catch (e) {
      // TODO better error handling
      debugPrint(e.toString());
    }
  }

  Future<void> setOffline() async {
    try {
      await _xelisWallet.offlineMode();
    } catch (e) {
      // TODO better error handling
      debugPrint(e.toString());
    }
  }

  void getMainData() {
    // TODO deserialize and yield event
    _xelisWallet.mainDataStream().listen((event) {
      debugPrint(event);
    });
  }

  void getDaemonInfo() {
    // TODO deserialize and yield event
    _xelisWallet.daemonInfoStream().listen((event) {
      debugPrint(event);
    });
  }
}
