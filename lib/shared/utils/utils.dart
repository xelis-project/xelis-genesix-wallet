import 'dart:convert';
import 'dart:math';
import 'package:genesix/features/wallet/domain/address.dart';
import 'package:genesix/rust_bridge/api/network.dart';
import 'package:genesix/rust_bridge/api/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

String formatCoin(int value, int decimals) {
  return (value / pow(10, decimals)).toStringAsFixed(decimals);
}

String formatXelis(int value) {
  return formatCoin(value, AppResources.xelisDecimals);
}

Address splitIntegratedAddress(String address) {
  var rawData = splitIntegratedAddressJson(integratedAddress: address);
  final json = jsonDecode(rawData);
  return Address.fromJson(json as Map<String, dynamic>);
}

Future<String> getAppCacheDirPath() async {
  if (kIsWeb) {
    return "/cache";
  } else {
    var dir = await getApplicationSupportDirectory();
    return dir.path;
  }
}

String localStorageDBPrefix = "___xelis_db___";

Future<String> getAppWalletsDirPath() async {
  if (kIsWeb) {
    return p.join(localStorageDBPrefix, AppResources.userWalletsFolderName);
  } else {
    var dir = await getApplicationDocumentsDirectory();
    var path = p.join(dir.path, AppResources.userWalletsFolderName);
    return path;
  }
}

Future<String> getWalletPath(Network network, String name) async {
  var walletsDir = await getAppWalletsDirPath();
  var path = p.join(walletsDir, network.name, name);
  return path;
}

String truncateText(String text, {int maxLength = 8}) {
  if (text.isEmpty) return "";
  if (text.length <= maxLength) return text;
  return "...${text.substring(text.length - maxLength)}";
}
