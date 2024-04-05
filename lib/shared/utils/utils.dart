import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;

String formatCoin(int value, int decimals) {
  return (value / pow(10, decimals)).toStringAsFixed(decimals);
}

String formatXelis(int value) {
  return formatCoin(value, AppResources.xelisDecimals);
}

Future<String> getAppCachePath() async {
  var dir = await getApplicationCacheDirectory();
  return Future.value(dir.path);
}

Future<String> getAppWalletsPath() async {
  var dir = await getApplicationDocumentsDirectory();
  var path = p.join(dir.path, 'wallets');
  return Future.value(path);
}

Future<String> getWalletPath(Network network, String name) async {
  var walletPath = await getAppWalletsPath();
  var path = p.join(walletPath, network.name, name);
  return Future.value(path);
}

String truncateAddress(String address) {
  return '...${address.substring(address.length - 8)}';
}
