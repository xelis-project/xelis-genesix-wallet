import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

XelisXswdPermissionRequest xswdTestPermission({
  required String method,
  Map<String, dynamic>? params,
  Object? id,
}) => XelisXswdRequest(
  kind: XelisXswdRequestKind.permission,
  application: _testApplication,
  payload: xswdTestPayload({
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
    'params': params,
  }),
).permissionRequest!;

XelisXswdPrefetchPermissionsRequest xswdTestPrefetch({
  required List<String> permissions,
  String? reason,
}) => XelisXswdRequest(
  kind: XelisXswdRequestKind.prefetchPermissions,
  application: _testApplication,
  payload: xswdTestPayload({'permissions': permissions, 'reason': reason}),
).prefetchPermissionsRequest!;

final _testApplication = XelisXswdApplication(
  id: 'fixture-id',
  name: 'Orbit Workshop',
  description: '',
  url: null,
  permissions: const {},
  isRelayer: false,
);

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
