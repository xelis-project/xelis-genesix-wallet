export 'unsupported.dart' if (dart.library.html) 'web.dart';

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'
    show NumberFormat, toBeginningOfSentenceCase, DateFormat, Intl;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

bool get isMobileDevice => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

bool get isDesktopDevice =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

bool isXelis(String assetHash) {
  return assetHash == sdk.xelisAsset;
}

// Usage: formatUsd(1234.5) -> $1,234.50
String formatUsd(num value, {bool withSymbol = true}) {
  final format = NumberFormat.currency(
    symbol: withSymbol ? '\$' : null,
    decimalDigits: 2,
  );
  return format.format(value);
}

String formatCoin(int value, int decimals, String ticker) {
  final pattern = '#,##0.${'#' * decimals}';
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
    case rust.Network.stagenet:
    case rust.Network.devnet:
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

void copyToClipboard(String content, WidgetRef ref, String toastMessage) {
  Clipboard.setData(ClipboardData(text: content)).then((_) {
    ref.read(toastProvider.notifier).showInformation(title: toastMessage);
  });
}

LinkedHashMap<K, V> sortMapByKey<K extends Comparable<K>, V>(Map<K, V> map) {
  return LinkedHashMap.fromEntries(
    map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

extension StringExtension on String {
  String capitalize() => toBeginningOfSentenceCase(this);

  String capitalizeAll() {
    return split(' ')
        .map((word) {
          return word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1)
              : '';
        })
        .join(' ');
  }
}

String translateThemeName(AppLocalizations loc, AppTheme theme) {
  switch (theme) {
    case AppTheme.dark:
      return loc.dark;
    case AppTheme.light:
      return loc.light;
    case AppTheme.xelis: // Keep for compatibility
      return 'XELIS';
  }
}

String translateLocaleName(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return '中文';
    case 'de':
      return 'Deutsch';
    case 'en':
      return 'English';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    case 'it':
      return 'Italiano';
    case 'ja':
      return '日本語';
    case 'ko':
      return '한국어';
    case 'pt':
      return 'Português';
    case 'ru':
      return 'Русский';
    case 'tr':
      return 'Turkiye';
    case 'nl':
      return 'Nederlands';
    case 'bg':
      return 'Български';
    case 'hi':
      return 'हिंदी';
    case 'ms':
      return 'Melayu';
    case 'pl':
      return 'Polski';
    case 'uk':
      return 'українська';
    case 'ar':
      return 'العربية';
    default:
      return 'N/A';
  }
}

String formatDifficulty(num value) {
  if (value >= 1e12) {
    return '${(value / 1e12).toStringAsFixed(2)} T';
  } else if (value >= 1e9) {
    return '${(value / 1e9).toStringAsFixed(2)} G';
  } else if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)} M';
  } else if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)} K';
  }
  // use global Intl.defaultLocale
  return NumberFormat.decimalPattern().format(value);
}

String formatHashRate({
  required String difficulty,
  required int blockTimeTarget, // en ms
}) {
  final difficultyValue = double.parse(difficulty);
  final blockTimeSeconds = blockTimeTarget / 1000;
  final value = difficultyValue / blockTimeSeconds;
  return '${formatDifficulty(value)}H/s';
}

// TODO: Localize this function
String timeAgo(AppLocalizations loc, DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(dateTime);

  if (diff.inSeconds < 60) {
    return loc.time_ago_now;
  } else if (diff.inMinutes < 60) {
    return Intl.plural(
      diff.inMinutes,
      one: loc.time_ago_minute,
      other: loc.time_ago_minutes(diff.inMinutes),
    );
  } else if (diff.inHours < 24) {
    return Intl.plural(
      diff.inHours,
      one: loc.time_ago_hour,
      other: loc.time_ago_hours(diff.inHours),
    );
  } else if (diff.inDays < 30) {
    return Intl.plural(
      diff.inDays,
      one: loc.time_ago_day,
      other: loc.time_ago_days(diff.inDays),
    );
  } else {
    // For more than 30 days, show the short date format (MM/dd/yyyy)
    return DateFormat(loc.datetime_format).format(dateTime);
  }
}

String formatDateNicely(DateTime date, Locale locale) {
  final now = DateTime.now();
  final isSameYear = date.year == now.year;

  // Format without year if it's the same year, otherwise include the year
  final formatter = DateFormat(
    isSameYear ? 'EEEE d MMMM' : 'EEEE d MMMM y',
    locale.languageCode,
  );

  return formatter.format(date);
}

String formatPrettyTimestamp(
  DateTime date,
  Locale locale, {
  bool includeSeconds = true,
}) {
  final tag = locale.toLanguageTag();

  final dateFormatter = DateFormat.yMMMMEEEEd(tag);

  final datePart = dateFormatter.format(date);

  final timeFormatter = includeSeconds
      ? DateFormat.jms(tag)
      : DateFormat.jm(tag);
  final timePart = timeFormatter.format(date);

  return '$datePart $timePart';
}

(String, String) getFormattedAssetNameAndAmount(
  Map<String, sdk.AssetData> knownAssets,
  String assetHash,
  int rawAmount,
) {
  final assetData = knownAssets[assetHash];
  if (assetData != null) {
    final formattedAmount = formatCoin(
      rawAmount,
      assetData.decimals,
      assetData.ticker,
    );
    return (assetData.name, formattedAmount);
  } else {
    // Fallback to default formatting if asset is not known
    return (truncateText(assetHash, maxLength: 20), rawAmount.toString());
  }
}
