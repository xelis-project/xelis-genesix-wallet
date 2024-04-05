import 'dart:convert';
import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

class LocaleJsonConverter implements JsonConverter<Locale, String> {
  const LocaleJsonConverter();

  @override
  Locale fromJson(String json) {
    final jsonLocale = jsonDecode(json);

    return Locale.fromSubtags(
      languageCode: jsonLocale['language_code'] as String,
      countryCode: jsonLocale['country_code'] as String?,
    );
  }

  @override
  String toJson(Locale locale) {
    return jsonEncode({
      'language_code': locale.languageCode,
      'country_code': locale.countryCode,
    });
  }
}
