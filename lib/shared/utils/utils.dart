export 'unsupported.dart' if (dart.library.html) 'web.dart';
export 'atomic_amount.dart';
export 'wallet_path.dart';

import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'
    show NumberFormat, toBeginningOfSentenceCase, DateFormat, Intl;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

import 'wallet_path.dart';

bool get isWebDevice => kIsWeb;

bool get isMobileDevice {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}

bool get isDesktopDevice {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return true;
    default:
      return false;
  }
}

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

// Usage: formatCurrency(1234.5, '€') -> €1,234.50
String formatCurrency(num value, String symbol, {bool withSymbol = true}) {
  final format = NumberFormat.currency(
    symbol: withSymbol ? symbol : null,
    decimalDigits: 2,
  );
  return format.format(value);
}

String _formatBigIntWithGrouping(BigInt value, NumberFormat decimalFormat) {
  if (value.bitLength <= 53) {
    return decimalFormat.format(value.toInt());
  }

  final groupSep = decimalFormat.symbols.GROUP_SEP;
  final digits = value.abs().toString();
  final buf = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final left = digits.length - i;
    buf.write(digits[i]);
    if (left > 1 && left % 3 == 1) {
      buf.write(groupSep);
    }
  }

  return value.isNegative
      ? '${decimalFormat.symbols.MINUS_SIGN}$buf'
      : buf.toString();
}

String formatBigInt(BigInt value, {String? locale}) {
  return _formatBigIntWithGrouping(value, NumberFormat.decimalPattern(locale));
}

/// Converts an atomic amount to an exact, non-localized decimal string.
///
/// This representation is intended for editable amount fields and comparisons
/// at the presentation boundary. It never converts through `double`, so values
/// beyond JavaScript's safe integer range remain lossless.
String formatAtomicAmount(BigInt value, int decimals) {
  if (decimals < 0) {
    throw ArgumentError.value(decimals, 'decimals', 'Must be >= 0');
  }

  final sign = value.isNegative ? '-' : '';
  final digits = value.abs().toString();
  if (decimals == 0) {
    return '$sign$digits';
  }

  final padded = digits.padLeft(decimals + 1, '0');
  final splitIndex = padded.length - decimals;
  return '$sign${padded.substring(0, splitIndex)}.'
      '${padded.substring(splitIndex)}';
}

String formatCoin(dynamic value, int decimals, String ticker) {
  BigInt amount;
  if (value is BigInt) {
    amount = value;
  } else if (value is int) {
    amount = BigInt.from(value);
  } else {
    throw ArgumentError.value(value, 'coin value', 'Must be a int or a BigInt');
  }

  if (decimals < 0) {
    throw ArgumentError.value(decimals, 'decimals', 'Must be >= 0');
  }

  final decimalFormat = NumberFormat.decimalPattern();

  if (decimals == 0) {
    final formattedInteger = _formatBigIntWithGrouping(amount, decimalFormat);
    return '$formattedInteger $ticker';
  }

  final divisor = BigInt.from(10).pow(decimals);
  final integerPart = amount ~/ divisor;
  final formattedInteger = _formatBigIntWithGrouping(
    integerPart,
    decimalFormat,
  );

  var fraction = (amount % divisor).toString().padLeft(decimals, '0');
  fraction = fraction.replaceFirst(RegExp(r'0+$'), '');

  if (fraction.isEmpty) {
    return '$formattedInteger $ticker';
  }

  final decimalSep = decimalFormat.symbols.DECIMAL_SEP;
  return '$formattedInteger$decimalSep$fraction $ticker';
}

String formatXelis(dynamic value, XelisNetwork network) {
  return formatCoin(value, AppResources.xelisDecimals, getXelisTicker(network));
}

String getXelisTicker(XelisNetwork network) {
  switch (network) {
    case XelisNetwork.mainnet:
      return 'XEL';
    case XelisNetwork.testnet:
    case XelisNetwork.stagenet:
    case XelisNetwork.devnet:
      return 'XET';
  }
}

DestinationAddress parseRawAddress({required String rawAddress}) {
  final descriptor = XelisWalletFlutter.parseAddress(address: rawAddress);
  return DestinationAddress(
    address: descriptor.baseAddress,
    data: descriptor.integratedData,
  );
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

Future<String> getWalletPath(XelisNetwork network, String name) async {
  final walletsDir = await getAppWalletsDirPath();
  return resolveWalletPath(
    walletsDirectory: walletsDir,
    networkName: network.name,
    walletName: name,
  );
}

Future<bool> isWalletFolderValid(String path) async {
  final rootType = await FileSystemEntity.type(path, followLinks: false);
  if (rootType != FileSystemEntityType.directory) return false;

  final dbType = await FileSystemEntity.type(
    p.join(path, 'db'),
    followLinks: false,
  );
  final configType = await FileSystemEntity.type(
    p.join(path, 'conf'),
    followLinks: false,
  );
  final blobsType = await FileSystemEntity.type(
    p.join(path, 'blobs'),
    followLinks: false,
  );
  return dbType == FileSystemEntityType.file &&
      configType == FileSystemEntityType.file &&
      blobsType == FileSystemEntityType.directory;
}

Future<bool> isWalletAlreadyExists({
  required XelisNetwork network,
  required String walletName,
}) async {
  final walletPath = await getWalletPath(network, walletName);
  final type = await FileSystemEntity.type(walletPath, followLinks: false);
  return type != FileSystemEntityType.notFound;
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
    case 'id':
      return 'Bahasa Indonesia';
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
  Map<String, XelisWalletAssetMetadata> knownAssets,
  String assetHash,
  dynamic rawAmount,
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
