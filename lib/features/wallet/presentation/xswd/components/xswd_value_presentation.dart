import 'dart:convert';
import 'dart:math' as math;

import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

const _maxPreviewCharacters = 96;
const _maxPreviewDepth = 4;

final class XswdValuePreview {
  const XswdValuePreview({
    required this.type,
    required this.text,
    required this.isTruncated,
  });

  final String type;
  final String text;
  final bool isTruncated;
}

/// Builds a bounded summary without serializing the complete value.
XswdValuePreview xswdRpcValuePreview(AppLocalizations loc, RpcValueCell cell) =>
    _rpcValuePreview(loc, cell, depth: 0);

XswdValuePreview _rpcValuePreview(
  AppLocalizations loc,
  RpcValueCell cell, {
  required int depth,
}) => switch (cell) {
  RpcPrimitiveValueCell(:final value) => _primitivePreview(value),
  RpcBytesValueCell(:final value) => _bytesPreview(value),
  RpcObjectValueCell(:final values) => _objectPreview(loc, values, depth),
  RpcMapValueCell(:final entries) => _mapPreview(loc, entries, depth),
  RpcUnknownValueCell() => throw StateError(
    'An unknown RPC value cannot be displayed for approval.',
  ),
};

XswdValuePreview _primitivePreview(RpcPrimitive primitive) =>
    switch (primitive) {
      RpcNullPrimitive() => _completePreview('null', 'null'),
      RpcBooleanPrimitive(:final value) => _completePreview(
        'boolean',
        '$value',
      ),
      RpcU8Primitive(:final value) => _completePreview('u8', '$value'),
      RpcU16Primitive(:final value) => _completePreview('u16', '$value'),
      RpcU32Primitive(:final value) => _completePreview('u32', '$value'),
      RpcU64Primitive(:final value) => _integerPreview('u64', value),
      RpcU128Primitive(:final value) => _integerPreview('u128', value),
      RpcU256Primitive(:final value) => _integerPreview('u256', value),
      RpcStringPrimitive(:final value) => _stringPreview(value),
      RpcRangePrimitive(:final start, :final end) => _rangePreview(start, end),
      RpcOpaquePrimitive(:final value) => _opaquePreview(value),
      RpcUnknownPrimitive() => throw StateError(
        'An unknown RPC primitive cannot be displayed for approval.',
      ),
    };

XswdValuePreview _completePreview(String type, String text) =>
    XswdValuePreview(type: type, text: text, isTruncated: false);

XswdValuePreview _integerPreview(String type, BigInt value) {
  final text = value.toString();
  return XswdValuePreview(
    type: type,
    text: _abbreviate(text, leading: 20, trailing: 0),
    isTruncated: text.length > 20,
  );
}

XswdValuePreview _stringPreview(String value) {
  const visibleCharacters = 30;
  final truncated = value.length > visibleCharacters;
  final visible = truncated ? _safePrefix(value, visibleCharacters) : value;
  return XswdValuePreview(
    type: 'string',
    text: jsonEncode(truncated ? '$visible…' : visible),
    isTruncated: truncated,
  );
}

XswdValuePreview _rangePreview(RpcPrimitive start, RpcPrimitive end) {
  final startPreview = _primitivePreview(start);
  final endPreview = _primitivePreview(end);
  final unbounded = '${startPreview.text}..${endPreview.text}';
  final text = _clip(unbounded);
  return XswdValuePreview(
    type: 'range<${_primitiveType(start)}, ${_primitiveType(end)}>',
    text: text,
    isTruncated:
        startPreview.isTruncated ||
        endPreview.isTruncated ||
        text.length < unbounded.length,
  );
}

String _primitiveType(
  RpcPrimitive primitive, {
  int depth = 0,
}) => switch (primitive) {
  RpcNullPrimitive() => 'null',
  RpcBooleanPrimitive() => 'boolean',
  RpcU8Primitive() => 'u8',
  RpcU16Primitive() => 'u16',
  RpcU32Primitive() => 'u32',
  RpcU64Primitive() => 'u64',
  RpcU128Primitive() => 'u128',
  RpcU256Primitive() => 'u256',
  RpcStringPrimitive() => 'string',
  RpcRangePrimitive(:final start, :final end) when depth < _maxPreviewDepth =>
    'range<${_primitiveType(start, depth: depth + 1)}, ${_primitiveType(end, depth: depth + 1)}>',
  RpcRangePrimitive() => 'range<…>',
  RpcOpaquePrimitive(:final value) => 'opaque<${value.type}>',
  RpcUnknownPrimitive() => 'unknown',
};

XswdValuePreview _opaquePreview(RpcOpaqueValue opaque) {
  final value = switch (opaque.value) {
    RpcJsonString(:final value) => value,
    _ => throw StateError(
      'A non-string opaque RPC value cannot be displayed for approval.',
    ),
  };
  final text = _abbreviate(value, leading: 8, trailing: 6);
  return XswdValuePreview(
    type: 'opaque<${opaque.type}>',
    text: text,
    isTruncated: text.length < value.length,
  );
}

XswdValuePreview _bytesPreview(List<int> bytes) {
  const leadingBytes = 8;
  const trailingBytes = 6;
  final truncated = bytes.length > leadingBytes + trailingBytes;
  final leading = _hex(bytes.take(leadingBytes));
  final text = truncated
      ? '$leading…${_hex(bytes.skip(bytes.length - trailingBytes))}'
      : _hex(bytes);
  return XswdValuePreview(type: 'bytes', text: text, isTruncated: truncated);
}

XswdValuePreview _objectPreview(
  AppLocalizations loc,
  List<RpcValueCell> values,
  int depth,
) {
  if (values.isEmpty) return _completePreview('object', '[]');
  if (values.length > 3 || depth >= _maxPreviewDepth) {
    return XswdValuePreview(
      type: 'object',
      text: '[${loc.item_count(values.length)}]',
      isTruncated: true,
    );
  }
  final children = values
      .map((value) => _rpcValuePreview(loc, value, depth: depth + 1))
      .toList(growable: false);
  final unbounded = '[${children.map((value) => value.text).join(', ')}]';
  final text = _clip(unbounded);
  return XswdValuePreview(
    type: 'object',
    text: text,
    isTruncated:
        children.any((value) => value.isTruncated) ||
        text.length < unbounded.length,
  );
}

XswdValuePreview _mapPreview(
  AppLocalizations loc,
  List<RpcValueCellEntry> entries,
  int depth,
) {
  if (entries.isEmpty) return _completePreview('map', '{}');
  if (entries.length > 1 || depth >= _maxPreviewDepth) {
    return XswdValuePreview(
      type: 'map',
      text: '{${loc.entry_count(entries.length)}}',
      isTruncated: true,
    );
  }
  final entry = entries.single;
  final key = _rpcValuePreview(loc, entry.key, depth: depth + 1);
  final value = _rpcValuePreview(loc, entry.value, depth: depth + 1);
  final unbounded = '{${key.text}: ${value.text}}';
  final text = _clip(unbounded);
  return XswdValuePreview(
    type: 'map',
    text: text,
    isTruncated:
        key.isTruncated || value.isTruncated || text.length < unbounded.length,
  );
}

/// Formats the exact value only after the user requests details.
String xswdFormatRpcValue(RpcValueCell cell) => switch (cell) {
  RpcPrimitiveValueCell(:final value) => _formatPrimitive(value),
  RpcBytesValueCell(:final value) => _hex(value),
  RpcObjectValueCell(:final values) =>
    '[${values.map(xswdFormatRpcValue).join(', ')}]',
  RpcMapValueCell(:final entries) =>
    '{${entries.map((entry) => '${xswdFormatRpcValue(entry.key)}: ${xswdFormatRpcValue(entry.value)}').join(', ')}}',
  RpcUnknownValueCell() => throw StateError(
    'An unknown RPC value cannot be displayed for approval.',
  ),
};

String _formatPrimitive(RpcPrimitive primitive) => switch (primitive) {
  RpcNullPrimitive() => 'null',
  RpcBooleanPrimitive(:final value) => '$value',
  RpcU8Primitive(:final value) ||
  RpcU16Primitive(:final value) ||
  RpcU32Primitive(:final value) => '$value',
  RpcU64Primitive(:final value) ||
  RpcU128Primitive(:final value) ||
  RpcU256Primitive(:final value) => value.toString(),
  RpcStringPrimitive(:final value) => jsonEncode(value),
  RpcRangePrimitive(:final start, :final end) =>
    '${_formatPrimitive(start)}..${_formatPrimitive(end)}',
  RpcOpaquePrimitive(:final value) => switch (value.value) {
    RpcJsonString(:final value) => value,
    _ => throw StateError(
      'A non-string opaque RPC value cannot be displayed for approval.',
    ),
  },
  RpcUnknownPrimitive() => throw StateError(
    'An unknown RPC primitive cannot be displayed for approval.',
  ),
};

/// Serializes the canonical SDK wire form only after an explicit reveal.
String xswdSerializeRpcValue(RpcValueCell cell) =>
    const JsonEncoder.withIndent('  ').convert(cell.toWireJson());

/// Builds a bounded attached-data summary without walking child collections.
String xswdDataElementPreview(AppLocalizations loc, DataElement element) =>
    switch (element) {
      DataValue(:final value) => _rpcJsonValuePreview(loc, value),
      DataArray(:final values) => '[${loc.item_count(values.length)}]',
      DataFields(:final fields) => '{${loc.entry_count(fields.length)}}',
      DataNull() => 'null',
    };

String _rpcJsonValuePreview(AppLocalizations loc, RpcJsonValue value) =>
    switch (value) {
      RpcJsonNullValue() => 'null',
      RpcJsonBoolean(:final value) => value ? 'true' : 'false',
      RpcJsonInteger(:final value) => _bigIntPreview(value),
      RpcJsonNumber(:final value) => jsonEncode(value),
      RpcJsonString(:final value) => _stringPreview(value).text,
      RpcJsonArray(:final values) => '[${loc.item_count(values.length)}]',
      RpcJsonObject(:final values) => '{${loc.entry_count(values.length)}}',
    };

String _bigIntPreview(BigInt value) {
  if (value.bitLength <= 512) {
    final text = value.toString();
    return _abbreviate(text, leading: 20, trailing: 0);
  }
  final digits = ((value.bitLength - 1) * math.log(2) / math.ln10).floor() + 1;
  return '<integer: ~$digits digits>';
}

/// Formats the complete, lossless attached data after explicit user action.
String xswdFormatDataElement(DataElement element, {int depth = 0}) =>
    switch (element) {
      DataValue(:final value) => _formatRpcJsonValue(value, depth: depth),
      DataArray(:final values) => _formatJsonArray(
        values.map((value) => xswdFormatDataElement(value, depth: depth + 1)),
        depth,
      ),
      DataFields(:final fields) => _formatJsonObject(
        fields.map(
          (key, value) =>
              MapEntry(key, xswdFormatDataElement(value, depth: depth + 1)),
        ),
        depth,
      ),
      DataNull() => 'null',
    };

/// Builds a bounded summary of typed data decoded from an integrated address.
XswdValuePreview xswdIntegratedDataPreview(
  AppLocalizations loc,
  wallet_flutter.XelisDataElement element,
) => switch (element) {
  wallet_flutter.XelisDataValueElement(:final value) => XswdValuePreview(
    type: _xelisDataValueType(value),
    text: loc.attached_data_included,
    isTruncated: true,
  ),
  wallet_flutter.XelisDataArray(:final values) => XswdValuePreview(
    type: 'array',
    text: '${loc.attached_data_included} (${loc.item_count(values.length)})',
    isTruncated: true,
  ),
  wallet_flutter.XelisDataFields(:final fields) => XswdValuePreview(
    type: 'fields',
    text: '${loc.attached_data_included} (${loc.entry_count(fields.length)})',
    isTruncated: true,
  ),
};

String _xelisDataValueType(wallet_flutter.XelisDataValue value) =>
    switch (value) {
      wallet_flutter.XelisDataBool() => 'boolean',
      wallet_flutter.XelisDataString() => 'string',
      wallet_flutter.XelisDataUnsigned(:final type) => type.name,
      wallet_flutter.XelisDataHash() => 'hash',
      wallet_flutter.XelisDataBlob() => 'blob',
    };

/// Formats typed integrated-address data exactly after explicit user action.
String xswdFormatIntegratedData(
  wallet_flutter.XelisDataElement element, {
  int depth = 0,
}) => switch (element) {
  wallet_flutter.XelisDataValueElement(:final value) => _formatXelisDataValue(
    value,
  ),
  wallet_flutter.XelisDataArray(:final values) => _formatJsonArray(
    values.map((value) => xswdFormatIntegratedData(value, depth: depth + 1)),
    depth,
  ),
  wallet_flutter.XelisDataFields(:final fields) => _formatXelisDataFields(
    fields,
    depth,
  ),
};

String _formatXelisDataValue(wallet_flutter.XelisDataValue value) =>
    switch (value) {
      wallet_flutter.XelisDataBool(:final value) => 'boolean($value)',
      wallet_flutter.XelisDataString(:final value) =>
        'string(${jsonEncode(value)})',
      wallet_flutter.XelisDataUnsigned(:final type, :final value) =>
        '${type.name}($value)',
      wallet_flutter.XelisDataHash(:final hex) => 'hash($hex)',
      wallet_flutter.XelisDataBlob(:final bytes) => 'blob(${_hex(bytes)})',
    };

String _formatXelisDataFields(
  List<wallet_flutter.XelisDataField> fields,
  int depth,
) {
  if (fields.isEmpty) return '{}';
  final indent = '  ' * (depth + 1);
  final closingIndent = '  ' * depth;
  final values = fields.map(
    (field) =>
        '${_formatXelisDataValue(field.key)}: '
        '${xswdFormatIntegratedData(field.value, depth: depth + 1)}',
  );
  return '{\n$indent${values.join(',\n$indent')}\n$closingIndent}';
}

String _formatRpcJsonValue(RpcJsonValue value, {required int depth}) =>
    switch (value) {
      RpcJsonNullValue() => 'null',
      RpcJsonBoolean(:final value) => value ? 'true' : 'false',
      RpcJsonInteger(:final value) => value.toString(),
      RpcJsonNumber(:final value) => jsonEncode(value),
      RpcJsonString(:final value) => jsonEncode(value),
      RpcJsonArray(:final values) => _formatJsonArray(
        values.map((value) => _formatRpcJsonValue(value, depth: depth + 1)),
        depth,
      ),
      RpcJsonObject(:final values) => _formatJsonObject(
        values.map(
          (key, value) =>
              MapEntry(key, _formatRpcJsonValue(value, depth: depth + 1)),
        ),
        depth,
      ),
    };

String _formatJsonArray(Iterable<String> values, int depth) {
  final items = values.toList(growable: false);
  if (items.isEmpty) return '[]';
  final indent = '  ' * (depth + 1);
  final closingIndent = '  ' * depth;
  return '[\n$indent${items.join(',\n$indent')}\n$closingIndent]';
}

String _formatJsonObject(Map<String, String> values, int depth) {
  if (values.isEmpty) return '{}';
  final indent = '  ' * (depth + 1);
  final closingIndent = '  ' * depth;
  final fields = values.entries.map(
    (entry) => '${jsonEncode(entry.key)}: ${entry.value}',
  );
  return '{\n$indent${fields.join(',\n$indent')}\n$closingIndent}';
}

String xswdAbbreviateIdentifier(String value) =>
    _abbreviate(value, leading: 8, trailing: 8);

String _hex(Iterable<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

String _safePrefix(String value, int length) {
  if (value.length <= length) return value;
  var end = length;
  final last = value.codeUnitAt(end - 1);
  if (last >= 0xd800 && last <= 0xdbff) end--;
  return value.substring(0, end);
}

String _abbreviate(
  String value, {
  required int leading,
  required int trailing,
}) {
  if (value.length <= leading + trailing) return value;
  final start = _safePrefix(value, leading);
  if (trailing == 0) return '$start…';
  return '$start…${value.substring(value.length - trailing)}';
}

String _clip(String value) {
  if (value.length <= _maxPreviewCharacters) return value;
  return '${_safePrefix(value, _maxPreviewCharacters - 1)}…';
}
