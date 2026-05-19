import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _endpoints = {
  'llms.txt': 'https://forui.dev/docs/llms.txt',
  'llms-full.txt': 'https://forui.dev/docs/llms-full.txt',
};

final _targetDirectory = Directory('.agents/references/forui');
final _metadataFile = File('${_targetDirectory.path}/metadata.json');

Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = 'Genesix Forui docs sync';

  try {
    final fetched = <String, _FetchedDoc>{};
    for (final entry in _endpoints.entries) {
      fetched[entry.key] = await _fetch(client, entry.value);
    }

    if (check) {
      final stale = <String>[];
      for (final entry in fetched.entries) {
        final local = File('${_targetDirectory.path}/${entry.key}');
        if (!local.existsSync() ||
            local.readAsStringSync() != entry.value.body) {
          stale.add(entry.key);
        }
      }

      if (stale.isNotEmpty) {
        stderr.writeln(
          'Forui docs snapshots are out of date: ${stale.join(', ')}',
        );
        exitCode = 1;
        return;
      }

      stdout.writeln('Forui docs snapshots are up to date.');
      return;
    }

    final metadata = _metadata(fetched);
    if (_isCurrent(fetched, metadata)) {
      stdout.writeln('Forui docs snapshots are already up to date.');
      return;
    }

    _targetDirectory.createSync(recursive: true);
    for (final entry in fetched.entries) {
      File(
        '${_targetDirectory.path}/${entry.key}',
      ).writeAsStringSync(entry.value.body);
    }

    _metadataFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
    stdout.writeln('Updated Forui docs snapshots in ${_targetDirectory.path}.');
  } finally {
    client.close(force: true);
  }
}

Map<String, Object?> _metadata(Map<String, _FetchedDoc> fetched) {
  return {
    'source': 'https://forui.dev/docs/reference/llms',
    'retrievedAt': DateTime.now().toUtc().toIso8601String(),
    'foruiVersion': _foruiVersion(),
    'documents': {
      for (final entry in fetched.entries)
        entry.key: {
          'url': entry.value.url,
          'sha256': entry.value.sha256,
          'bytes': utf8.encode(entry.value.body).length,
        },
    },
  };
}

bool _isCurrent(
  Map<String, _FetchedDoc> fetched,
  Map<String, Object?> nextMetadata,
) {
  for (final entry in fetched.entries) {
    final local = File('${_targetDirectory.path}/${entry.key}');
    if (!local.existsSync() || local.readAsStringSync() != entry.value.body) {
      return false;
    }
  }

  if (!_metadataFile.existsSync()) {
    return false;
  }

  final existing = jsonDecode(_metadataFile.readAsStringSync());
  if (existing is! Map<String, Object?>) {
    return false;
  }

  if (existing['foruiVersion'] != nextMetadata['foruiVersion']) {
    return false;
  }

  final existingDocuments = existing['documents'];
  final nextDocuments = nextMetadata['documents'];
  if (existingDocuments is! Map || nextDocuments is! Map) {
    return false;
  }

  for (final entry in _endpoints.entries) {
    final existingDocument = existingDocuments[entry.key];
    final nextDocument = nextDocuments[entry.key];
    if (existingDocument is! Map || nextDocument is! Map) {
      return false;
    }
    if (existingDocument['sha256'] != nextDocument['sha256']) {
      return false;
    }
  }

  return true;
}

Future<_FetchedDoc> _fetch(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      'Failed to fetch $url: HTTP ${response.statusCode}',
      uri: Uri.parse(url),
    );
  }

  final body = await utf8.decodeStream(response);
  final digest = sha256.convert(utf8.encode(body)).toString();
  return _FetchedDoc(url: url, body: body, sha256: digest);
}

String? _foruiVersion() {
  final lockfile = File('pubspec.lock');
  if (!lockfile.existsSync()) {
    return null;
  }

  final lines = lockfile.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() == 'forui:') {
      for (var j = i + 1; j < lines.length; j++) {
        final line = lines[j];
        if (!line.startsWith('    ') && line.trim().endsWith(':')) {
          return null;
        }

        final match = RegExp(
          r'^\s+version:\s+"?([^"]+)"?\s*$',
        ).firstMatch(line);
        if (match != null) {
          return match.group(1);
        }
      }
    }
  }

  return null;
}

class _FetchedDoc {
  const _FetchedDoc({
    required this.url,
    required this.body,
    required this.sha256,
  });

  final String url;
  final String body;
  final String sha256;
}
