export 'unsupported.dart' if (dart.library.html) 'web.dart';

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat, toBeginningOfSentenceCase;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;

String formatCoin(int value, int decimals, String ticker) {
  final pattern = '#,##0.${'#' * AppResources.xelisDecimals}';
  final formatter = NumberFormat(pattern);
  final xelisValue = formatter.format(value / pow(10, decimals));
  return '$xelisValue $ticker';
}

String formatXelis(int value, rust.Network network) {
  final pattern = '#,##0.${'#' * AppResources.xelisDecimals}';
  final formatter = NumberFormat(pattern);
  final xelisValue = formatter.format(
    value / pow(10, AppResources.xelisDecimals),
  );
  return '$xelisValue ${getXelisTicker(network)}';
}

String getXelisTicker(rust.Network network) {
  switch (network) {
    case rust.Network.mainnet:
      return 'XEL';
    case rust.Network.testnet:
    case rust.Network.dev:
      return 'XET';
  }
}

DestinationAddress parseRawAddress({required String rawAddress}) {
  var rawData = splitIntegratedAddress(integratedAddress: rawAddress);
  final json = jsonDecode(rawData);
  return DestinationAddress.fromJson(json as Map<String, dynamic>);
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

void copyToClipboard(String content, WidgetRef ref, String snackbarMessage) {
  Clipboard.setData(ClipboardData(text: content)).then((_) {
    ref
        .read(snackBarQueueProvider.notifier)
        .showInfo(snackbarMessage, duration: Duration(seconds: 1));
  });
}

LinkedHashMap<K, V> sortMapByKey<K extends Comparable<K>, V>(Map<K, V> map) {
  return LinkedHashMap.fromEntries(
    map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

extension StringExtension on String {
  String capitalize() => toBeginningOfSentenceCase(this);
}
