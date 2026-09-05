import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _maxDepth = 64;
const _maxNodes = 300000;
const _maxStringCharacters = 2 * 1024 * 1024;
const _maxTextCharacters = 3 * 1024 * 1024;
final _maxExactMultiplierInteger = BigInt.from(9007199254740991);

/// Converts the authored, exact XWF projection for the SDK's fromJson APIs.
/// Integers remain BigInt; no JSON encoding/decoding participates in authority.
Map<String, dynamic> decodeXswdPayload(XelisXswdValue? payload) {
  if (payload is! XelisXswdObjectValue) {
    throw const FormatException('Invalid XSWD payload root.');
  }
  return _XswdPayloadDecoder().decode(payload, 0) as Map<String, dynamic>;
}

/// The SDK still authors these protocol-bounded fields as Dart int, and the
/// upstream fee multiplier as f64. All other integer fields stay BigInt.
void normalizeXswdBuildTransactionFields(Map<String, dynamic> request) {
  if (request['method'] != 'build_transaction') return;
  final params = request['params'];
  if (params is! Map<String, dynamic>) return;
  _normalizeSmallInteger(params, 'tx_version', 3);
  if (params['multi_sig'] case final Map<String, dynamic> multisig) {
    _normalizeSmallInteger(multisig, 'threshold', 255);
  }
  if (params['invoke_contract'] case final Map<String, dynamic> invoke) {
    _normalizeSmallInteger(invoke, 'entry_id', 65535);
  }
  final fee = params['fee'];
  if (fee is! Map<String, dynamic>) return;
  final extra = fee['extra'];
  if (extra is! Map<String, dynamic>) return;
  if (extra['multiplier'] case final BigInt multiplier) {
    if (multiplier < BigInt.zero || multiplier > _maxExactMultiplierInteger) {
      throw const FormatException('Fee multiplier cannot be reviewed exactly.');
    }
    extra['multiplier'] = multiplier.toInt();
  }
}

void _normalizeSmallInteger(Map<String, dynamic> object, String key, int max) {
  if (object[key] case final BigInt value) {
    if (value < BigInt.zero || value > BigInt.from(max)) {
      throw const FormatException('Invalid bounded XSWD integer.');
    }
    object[key] = value.toInt();
  }
}

final class _XswdPayloadDecoder {
  int _nodes = 0;
  int _textCharacters = 0;

  Object? decode(XelisXswdValue value, int depth) {
    if (++_nodes > _maxNodes || depth > _maxDepth) {
      throw const FormatException('XSWD review budget exceeded.');
    }
    return switch (value) {
      XelisXswdNullValue() => null,
      XelisXswdBoolValue(:final value) => value,
      XelisXswdIntegerValue(:final value) => value,
      XelisXswdFloatValue(:final value) => _finiteDouble(value),
      XelisXswdStringValue(:final value) => _text(value),
      XelisXswdArrayValue(:final values) => [
        for (final child in values) decode(child, depth + 1),
      ],
      XelisXswdObjectValue(:final fields) => <String, dynamic>{
        for (final entry in fields.entries)
          _text(entry.key): decode(entry.value, depth + 1),
      },
    };
  }

  String _text(String value) {
    _textCharacters += value.length;
    if (value.length > _maxStringCharacters ||
        _textCharacters > _maxTextCharacters) {
      throw const FormatException('XSWD review text budget exceeded.');
    }
    return value;
  }
}

double _finiteDouble(double value) {
  if (!value.isFinite) {
    throw const FormatException('Invalid XSWD floating-point value.');
  }
  return value;
}
