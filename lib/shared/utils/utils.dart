import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:genesix/features/wallet/domain/address.dart';
import 'package:genesix/rust_bridge/api/network.dart';
import 'package:genesix/rust_bridge/api/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

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

Future<bool> isWalletFolderValid(String path) async {
  if (await File('$path/db').exists() &&
      await File('$path/conf').exists() &&
      await Directory('$path/blobs').exists()) {
    return true;
  }
  return false;
}

Future<bool> isWalletAlreadyExists(String path, Network network) async {
  final walletName = path.split(p.separator).last;
  final walletsDir = await getAppWalletsDirPath();
  return Directory(p.join(walletsDir, network.name, walletName)).exists();
}

String truncateText(String text, {int maxLength = 8}) {
  if (text.isEmpty) return "";
  if (text.length <= maxLength) return text;
  return "...${text.substring(text.length - maxLength)}";
}

void saveTextFile(String text, String filename) {
  final bytes = utf8.encode(text);
  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = "data:application/octet-stream;base64,${base64Encode(bytes)}"
        ..style.display = 'none'
        ..download = filename;

  web.document.body!.appendChild(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);
}
