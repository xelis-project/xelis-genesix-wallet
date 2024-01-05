import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/xelis_network.dart';
import 'package:xelis_mobile_wallet/src/rust/api/wallet.dart';

class NativeWalletRepository {
  NativeWalletRepository._internal(this._xelisWallet);

  final XelisWallet _xelisWallet;

  static Future<NativeWalletRepository> create(
      String name, String pwd, Network network,
      {String? seed}) async {
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
    // _xelisWallet.wallet.dispose();
  }

  Future<String> get humanReadableAddress => _xelisWallet.getAddressStr();

  Future<int> get nonce => _xelisWallet.getNonce();

  Future<bool> get isOnline => _xelisWallet.isOnline();

  Future<String> getSeed(int languageIndex) async {
    String seed = await _xelisWallet.getSeed(languageIndex: languageIndex);
    return seed;
  }

  Future<void> setOnline({required String daemonAddress}) async {
    try {
      await _xelisWallet.setOnlineMode(daemonAddress: daemonAddress);
    } catch (e) {
      // TODO better error handling
      debugPrint(e.toString());
    }
  }

  Future<void> setOffline() async {
    try {
      await _xelisWallet.setOfflineMode();
    } catch (e) {
      // TODO better error handling
      debugPrint(e.toString());
    }
  }
}
