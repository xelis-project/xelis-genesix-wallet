import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';

@freezed
class Settings with _$Settings {
  const factory Settings({
    required bool isDarkMode,
    required String languageSelected,
    required String daemonAddressSelected,
    required List<String> daemonAddresses,
  }) = _Settings;
}
