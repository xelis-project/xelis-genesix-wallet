import 'dart:convert';
import 'dart:typed_data';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ParsedExtraData {
  final ExtraData extra;
  final String label; // 'JSON' | 'Text' | 'UTF-8' | 'Bytes' | 'Unknown'
  final int bytesLength; // computed size in bytes
  final String pretty; // what is shown in the UI
  final String copyText; // what is copied to clipboard
  final String suggestedExt; // .json / .txt / .bin
  final Flag flag; // private/public/proprietary/failed
  final String? sharedKeyRedacted; // "abcd…1234" / "Bytes(32)" / null

  ParsedExtraData({
    required this.extra,
    required this.label,
    required this.bytesLength,
    required this.pretty,
    required this.copyText,
    required this.suggestedExt,
    required this.flag,
    required this.sharedKeyRedacted,
  });

  String get fmtSize => _formatBytes(bytesLength);

  /// Simple parser : Map/List → JSON, String → JSON|text, Bytes → UTF8|hexa preview.
  static ParsedExtraData parse(AppLocalizations loc, ExtraData x) {
    final data = x.data;

    String label = loc.unknown;
    String pretty = '';
    String copy = '';
    String ext = '.txt';
    int size = 0;

    if (data is Map || data is List) {
      pretty = const JsonEncoder.withIndent('  ').convert(data);
      copy = pretty;
      label = 'JSON';
      ext = '.json';
      size = utf8.encode(pretty).length;
    } else if (data is String) {
      final j = _tryJson(data);
      if (j != null) {
        pretty = const JsonEncoder.withIndent('  ').convert(j);
        copy = pretty;
        label = 'JSON';
        ext = '.json';
        size = utf8.encode(pretty).length;
      } else {
        pretty = data;
        copy = data;
        label = loc.text;
        ext = '.txt';
        size = utf8.encode(data).length;
      }
    } else if (data is Uint8List) {
      final asUtf8 = _tryUtf8(data);
      if (asUtf8 != null) {
        pretty = asUtf8;
        copy = asUtf8;
        label = 'UTF-8';
        ext = '.txt';
      } else {
        pretty = _hexPreview(data, maxBytes: 512);
        copy = _hexFull(data);
        label = loc.bytes;
        ext = '.bin';
      }
      size = data.length;
    } else {
      final s = data.toString();
      pretty = s;
      copy = s;
      label = data.runtimeType.toString();
      ext = '.txt';
      size = utf8.encode(s).length;
    }

    // sharedKey → optional redacted version for display
    final redacted = _redactSharedKey(x.sharedKey);

    return ParsedExtraData(
      extra: x,
      label: label,
      bytesLength: size,
      pretty: pretty,
      copyText: copy,
      suggestedExt: ext,
      flag: x.flag,
      sharedKeyRedacted: redacted,
    );
  }
}

/// --- Helpers ---

Object? _tryJson(String s) {
  try {
    final d = json.decode(s);
    if (d is Map || d is List) return d;
    return null;
  } catch (_) {
    return null;
  }
}

String? _tryUtf8(Uint8List bytes) {
  try {
    final s = utf8.decode(bytes, allowMalformed: false);
    final printable = RegExp(r'^[\x09\x0A\x0D\x20-\x7E\u0080-\uFFFF]+$');
    return printable.hasMatch(s) ? s : null;
  } catch (_) {
    return null;
  }
}

String _hexFull(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

String _hexPreview(Uint8List bytes, {int maxBytes = 512, int lineChars = 64}) {
  final take = bytes.length > maxBytes ? bytes.sublist(0, maxBytes) : bytes;
  final hex = _hexFull(take);
  final buf = StringBuffer();
  for (var i = 0; i < hex.length; i += lineChars) {
    final end = (i + lineChars > hex.length) ? hex.length : i + lineChars;
    buf.writeln(hex.substring(i, end));
  }
  if (bytes.length > maxBytes) {
    buf.writeln('… (${bytes.length - maxBytes} bytes more)');
  }
  return buf.toString();
}

String _formatBytes(int b) {
  const k = 1024.0;
  if (b < k) return '$b B';
  final kb = b / k;
  if (kb < k) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / k;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

/// sharedKey can be null / String / Uint8List / other.
/// We return a redacted version for display, or null if not set.
String? _redactSharedKey(dynamic sk) {
  if (sk == null) return null;
  if (sk is String) {
    final s = sk.trim();
    if (s.isEmpty) return null;
    if (s.length <= 12) return s;
    return '${s.substring(0, 6)}…${s.substring(s.length - 6)}';
  }
  if (sk is Uint8List) {
    return 'Bytes(${sk.length})';
  }
  final s = sk.toString();
  if (s.isEmpty) return null;
  return s.length <= 12
      ? s
      : '${s.substring(0, 6)}…${s.substring(s.length - 6)}';
}
