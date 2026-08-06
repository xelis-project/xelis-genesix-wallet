import 'dart:convert';
import 'dart:typed_data';

import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Presentation-only, lossless formatting of one typed XELIS data element.
///
/// The source value remains in the caller-owned reveal flow. This projection
/// contains only the strings needed by the currently visible sheet and is
/// never persisted or logged.
final class ParsedXelisDataElement {
  const ParsedXelisDataElement({
    required this.label,
    required this.bytesLength,
    required this.pretty,
    required this.copyText,
    required this.suggestedExt,
  });

  final String label;
  final int? bytesLength;
  final String pretty;
  final String copyText;
  final String suggestedExt;

  String? get fmtSize => switch (bytesLength) {
    final bytes? => _formatBytes(bytes),
    null => null,
  };

  static ParsedXelisDataElement parse(
    AppLocalizations loc,
    XelisDataElement data,
  ) {
    final parsed = _parseTypedPayload(data, loc);
    return ParsedXelisDataElement(
      label: parsed.label,
      bytesLength: parsed.bytesLength,
      pretty: parsed.pretty,
      copyText: parsed.copyText,
      suggestedExt: parsed.extension,
    );
  }
}

class ParsedExtraData {
  final XelisWalletExtraData extra;
  final String label;
  final int? bytesLength;
  final String pretty;
  final String copyText;
  final String suggestedExt;
  final XelisWalletExtraDataFlag flag;

  ParsedExtraData({
    required this.extra,
    required this.label,
    required this.bytesLength,
    required this.pretty,
    required this.copyText,
    required this.suggestedExt,
    required this.flag,
  });

  String? get fmtSize => switch (bytesLength) {
    final bytes? => _formatBytes(bytes),
    null => null,
  };

  /// Parses explicit history payloads without ever handling encryption keys.
  ///
  /// Structured and numeric JSON is never decoded and re-encoded, so values
  /// above JavaScript's safe-integer range remain exact on Web.
  static ParsedExtraData parse(AppLocalizations loc, XelisWalletExtraData x) {
    final typedPayload = x.payload;
    if (typedPayload != null) {
      final payload = ParsedXelisDataElement.parse(loc, typedPayload);
      return ParsedExtraData(
        extra: x,
        label: payload.label,
        bytesLength: payload.bytesLength,
        pretty: payload.pretty,
        copyText: payload.copyText,
        suggestedExt: payload.suggestedExt,
        flag: x.flag,
      );
    }

    return ParsedExtraData(
      extra: x,
      label: loc.not_available,
      bytesLength: null,
      pretty: loc.not_available,
      copyText: '',
      suggestedExt: '.txt',
      flag: x.flag,
    );
  }
}

typedef _ParsedPayload = ({
  String label,
  int? bytesLength,
  String pretty,
  String copyText,
  String extension,
});

_ParsedPayload _parseTypedPayload(
  XelisDataElement payload,
  AppLocalizations loc,
) => switch (payload) {
  XelisDataValueElement(:final value) => _parseTypedValue(value, loc),
  XelisDataArray() || XelisDataFields() => _parseTypedStructure(payload),
};

_ParsedPayload _parseTypedValue(XelisDataValue value, AppLocalizations loc) =>
    switch (value) {
      XelisDataBool(:final value) => _textPayload(
        value.toString(),
        label: 'Bool',
        bytesLength: 1,
        extension: '.json',
      ),
      XelisDataString(:final value) => _textPayload(
        value,
        label: loc.text,
        bytesLength: utf8.encode(value).length,
        extension: '.txt',
      ),
      XelisDataUnsigned(:final type, :final value) => _textPayload(
        value.toString(),
        label: type.name.toUpperCase(),
        bytesLength: _unsignedByteLength(type),
        extension: '.json',
      ),
      XelisDataHash(:final hex) => _textPayload(
        hex,
        label: 'Hash',
        bytesLength: 32,
        extension: '.txt',
      ),
      XelisDataBlob(:final bytes) => _parseBlobBytes(
        Uint8List.fromList(bytes),
        loc,
      ),
    };

_ParsedPayload _parseTypedStructure(XelisDataElement payload) {
  final formatted = const JsonEncoder.withIndent(
    '  ',
  ).convert(_taggedElement(payload));
  return _textPayload(
    formatted,
    label: 'JSON',
    bytesLength: utf8.encode(formatted).length,
    extension: '.json',
  );
}

Object _taggedElement(XelisDataElement element) => switch (element) {
  XelisDataValueElement(:final value) => _taggedValue(value),
  XelisDataArray(:final values) => <String, Object>{
    'array': values.map(_taggedElement).toList(),
  },
  XelisDataFields(:final fields) => <String, Object>{
    'fields': fields
        .map(
          (field) => <String, Object>{
            'key': _taggedValue(field.key),
            'value': _taggedElement(field.value),
          },
        )
        .toList(),
  },
};

Object _taggedValue(XelisDataValue value) => switch (value) {
  XelisDataBool(:final value) => <String, Object>{'bool': value},
  XelisDataString(:final value) => <String, Object>{'string': value},
  XelisDataUnsigned(:final type, :final value) => <String, Object>{
    type.name: value.toString(),
  },
  XelisDataHash(:final hex) => <String, Object>{'hash': hex},
  XelisDataBlob(:final bytes) => <String, Object>{'blob': bytes},
};

int _unsignedByteLength(XelisUnsignedIntegerType type) => switch (type) {
  XelisUnsignedIntegerType.u8 => 1,
  XelisUnsignedIntegerType.u16 => 2,
  XelisUnsignedIntegerType.u32 => 4,
  XelisUnsignedIntegerType.u64 => 8,
  XelisUnsignedIntegerType.u128 => 16,
};

_ParsedPayload _textPayload(
  String value, {
  required String label,
  required int bytesLength,
  required String extension,
}) => (
  label: label,
  bytesLength: bytesLength,
  pretty: value,
  copyText: value,
  extension: extension,
);

_ParsedPayload _parseBlobBytes(Uint8List bytes, AppLocalizations loc) {
  final text = _tryUtf8(bytes);
  if (text != null) {
    return (
      label: 'UTF-8',
      bytesLength: bytes.length,
      pretty: text,
      copyText: text,
      extension: '.txt',
    );
  }
  return (
    label: loc.bytes,
    bytesLength: bytes.length,
    pretty: _hexPreview(bytes),
    copyText: _hexFull(bytes),
    extension: '.bin',
  );
}

String? _tryUtf8(Uint8List bytes) {
  try {
    final value = utf8.decode(bytes, allowMalformed: false);
    final printable = RegExp(r'^[\x09\x0A\x0D\x20-\x7E\u0080-\uFFFF]*$');
    return printable.hasMatch(value) ? value : null;
  } on FormatException {
    return null;
  }
}

String _hexFull(Uint8List bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

String _hexPreview(Uint8List bytes, {int maxBytes = 512, int lineChars = 64}) {
  final visibleBytes = bytes.length > maxBytes
      ? bytes.sublist(0, maxBytes)
      : bytes;
  final hex = _hexFull(visibleBytes);
  final buffer = StringBuffer();
  for (var offset = 0; offset < hex.length; offset += lineChars) {
    final end = (offset + lineChars > hex.length)
        ? hex.length
        : offset + lineChars;
    buffer.writeln(hex.substring(offset, end));
  }
  if (bytes.length > maxBytes) {
    buffer.writeln('… (${bytes.length - maxBytes} bytes more)');
  }
  return buffer.toString();
}

String _formatBytes(int bytes) {
  const kilo = 1024.0;
  if (bytes < kilo) return '$bytes B';
  final kilobytes = bytes / kilo;
  if (kilobytes < kilo) {
    return '${kilobytes.toStringAsFixed(kilobytes < 10 ? 1 : 0)} KB';
  }
  final megabytes = kilobytes / kilo;
  return '${megabytes.toStringAsFixed(megabytes < 10 ? 1 : 0)} MB';
}
