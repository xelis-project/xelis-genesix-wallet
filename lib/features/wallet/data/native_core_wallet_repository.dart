/*
import 'package:path_provider/path_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/xelis_network.dart';
import 'package:xelis_mobile_wallet/src/rust/api/core_wallet.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as dart_sdk;

class NativeCoreWalletRepository {
  NativeCoreWalletRepository._internal(this._coreWallet);

  final CoreWallet _coreWallet;

  // Future<int> is() async {
  //   return CoreWallet.testU();
  // }
  //
  static Future<NativeCoreWalletRepository> create(
      String name, String pwd, dart_sdk.Network network,
      {String? seed}) async {
    await setNetwork(network);
    final dir = await getApplicationDocumentsDirectory();
    final coreWallet = await createWallet(
        name: '${dir.path}/$name', password: pwd, seed: seed);
    return NativeCoreWalletRepository._internal(coreWallet);
  }

  static Future<NativeCoreWalletRepository> open(
      String name, String pwd, dart_sdk.Network network,
      {String? seed}) async {
    await setNetwork(network);
    final dir = await getApplicationDocumentsDirectory();
    final coreWallet =
        await openWallet(name: '${dir.path}/$name', password: pwd);
    return NativeCoreWalletRepository._internal(coreWallet);
  }

  Future<String> get humanReadableAddress => _coreWallet.getAddress();

  Future<bool> get isOnline => _coreWallet.isOnline();
}
*/
