import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Builds the same integer/string distinctions as XWF's Rust projection.
XelisXswdValue xswdTestPayload(Object? value) => switch (value) {
  null => const XelisXswdNullValue(),
  bool value => XelisXswdBoolValue(value),
  BigInt value => XelisXswdIntegerValue(value),
  int value => XelisXswdIntegerValue(BigInt.from(value)),
  double value => XelisXswdFloatValue(value),
  String value => XelisXswdStringValue(value),
  List<Object?> values => XelisXswdArrayValue(
    values.map(xswdTestPayload).toList(growable: false),
  ),
  Map<String, Object?> fields => XelisXswdObjectValue(
    fields.map((key, value) => MapEntry(key, xswdTestPayload(value))),
  ),
  _ => throw ArgumentError('Unsupported XSWD test fixture type.'),
};
