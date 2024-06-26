import 'dart:math';
import 'package:genesix/rust_bridge/api/network.dart';
import 'package:path_provider/path_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;

String formatCoin(int value, int decimals) {
  return (value / pow(10, decimals)).toStringAsFixed(decimals);
}

String formatXelis(int value) {
  return formatCoin(value, AppResources.xelisDecimals);
}

Future<String> getAppCacheDirPath() async {
  var dir = await getApplicationCacheDirectory();
  return dir.path;
}

Future<String> getAppWalletsDirPath() async {
  var dir = await getApplicationDocumentsDirectory();
  var path = p.join(dir.path, AppResources.userWalletsFolderName);
  return path;
}

Future<String> getWalletPath(Network network, String name) async {
  var walletsDir = await getAppWalletsDirPath();
  var path = p.join(walletsDir, network.name, name);
  return path;
}

String truncateAddress(String address) {
  if (address.isEmpty) return "";
  return "...${address.substring(address.length - 8)}";
}
