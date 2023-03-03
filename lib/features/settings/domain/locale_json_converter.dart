import 'dart:convert';
import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

class LocaleJsonConverter implements JsonConverter<Locale, String> {
  const LocaleJsonConverter();

  @override
  Locale fromJson(String json) {
    final jsonLocale = jsonDecode(json) as Map<String, dynamic>;
    return Locale.fromSubtags(
      languageCode: jsonLocale['languageCode'] as String,
      countryCode: jsonLocale['countryCode'] as String,
    );
  }

  @override
  String toJson(Locale locale) {
    return jsonEncode({
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode
    });
  }
}
