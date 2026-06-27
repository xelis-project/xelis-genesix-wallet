import 'dart:convert';
import 'dart:io';

import 'package:genesix/features/news/domain/news_feed_contract.dart';

void main() {
  final file = File('news/index.json');
  if (!file.existsSync()) {
    _fail('Missing news/index.json');
  }

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    _fail('news/index.json must contain a JSON object');
  }

  final items = decoded['items'];
  if (items is! List) {
    _fail('news/index.json must contain an items array');
  }

  final ids = <String>{};
  for (final item in items) {
    if (item is! Map<String, dynamic>) {
      _fail('Every news item must be an object');
    }

    final id = _requiredString(item, 'id');
    if (!ids.add(id)) {
      _fail('Duplicate news id: $id');
    }

    _requiredDate(item, 'publishedAt');
    _optionalDate(item, 'expiresAt');
    final type = _requiredString(item, 'type').toLowerCase();
    if (!allowedNewsTypes.contains(type)) {
      _fail('Invalid "type" for "$id": $type');
    }
    final severity = _requiredString(item, 'severity').toLowerCase();
    if (!allowedNewsSeverities.contains(severity)) {
      _fail('Invalid "severity" for "$id": $severity');
    }
    if (severity == 'critical' && item['expiresAt'] == null) {
      _fail('Critical news "$id" must define expiresAt');
    }
    _localizedMap(item, 'title');
    _localizedMap(item, 'summary');
    _validateTargets(item['targets']);
    _validateLinks(item['links']);
  }

  stdout.writeln('Validated ${items.length} news item(s).');
}

String _requiredString(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value is! String || value.trim().isEmpty) {
    _fail('Missing or invalid "$key"');
  }

  return value.trim();
}

void _requiredDate(Map<String, dynamic> item, String key) {
  final value = _requiredString(item, key);
  if (DateTime.tryParse(value) == null) {
    _fail('Invalid "$key" date: $value');
  }
}

void _optionalDate(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value == null) {
    return;
  }
  if (value is! String || DateTime.tryParse(value) == null) {
    _fail('Invalid "$key" date');
  }
}

void _localizedMap(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value is! Map<String, dynamic> || value.isEmpty) {
    _fail('Missing or invalid "$key" localized map');
  }
  if (!value.containsKey('en')) {
    _fail('"$key" must contain an "en" fallback');
  }

  for (final entry in value.entries) {
    final languageCode = entry.key.trim().toLowerCase();
    if (!supportedNewsLanguages.contains(languageCode)) {
      _fail('Unsupported language "$languageCode" in "$key"');
    }
    if (languageCode.isEmpty ||
        entry.value is! String ||
        (entry.value as String).trim().isEmpty) {
      _fail('Invalid "$key" localized entry');
    }
  }
}

void _validateTargets(Object? value) {
  if (value == null) {
    return;
  }
  if (value is! Map<String, dynamic>) {
    _fail('"targets" must be an object');
  }

  _optionalStringList(value, 'networks');
  _optionalStringList(value, 'platforms');
  _validateAllowedStringList(value, 'networks', allowedNewsNetworks);
  _validateAllowedStringList(value, 'platforms', allowedNewsPlatforms);
}

void _optionalStringList(Map<String, dynamic> item, String key) {
  final value = item[key];
  if (value == null) {
    return;
  }
  if (value is! List || value.any((entry) => entry is! String)) {
    _fail('"$key" must be an array of strings');
  }
}

void _validateAllowedStringList(
  Map<String, dynamic> item,
  String key,
  Set<String> allowed,
) {
  final value = item[key];
  if (value == null) {
    return;
  }

  for (final entry in value as List) {
    final normalized = (entry as String).trim().toLowerCase();
    if (!allowed.contains(normalized)) {
      _fail('Invalid "$key" value: $entry');
    }
  }
}

void _validateLinks(Object? value) {
  if (value == null) {
    return;
  }
  if (value is! List) {
    _fail('"links" must be an array');
  }
  if (value.length > 3) {
    _fail('"links" must contain at most 3 entries');
  }

  for (final link in value) {
    if (link is! Map<String, dynamic>) {
      _fail('Every link must be an object');
    }

    _localizedMap(link, 'label');
    final url = Uri.tryParse(_requiredString(link, 'url'));
    if (url == null || !isAllowedNewsUrl(url)) {
      _fail('Invalid or disallowed link URL: ${link['url']}');
    }
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exitCode = 1;
  exit(1);
}
