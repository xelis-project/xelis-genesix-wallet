import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/xswd_diagnostics.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

import '../../../helpers/xswd_test_payload.dart';

void main() {
  test(
    'classifies exact methods without granting or normalizing permissions',
    () {
      final diagnostic = XswdDiagnosticRequest.inspect(
        _request({
          'permissions': [
            'get_balance',
            'subscribe',
            'wallet.get_balance',
            'build_transaction',
            'get_tracked_assets',
            'track_asset',
            'untrack_asset',
            'sign_data',
          ],
          'reason': 'SENSITIVE_REASON',
          'params': {'method': 'SENSITIVE_PARAMETER'},
        }),
      );
      final record = jsonDecode(
        diagnostic.format(XswdDiagnosticEvent.received),
      ) as Map<String, dynamic>;
      expect(record['methods'], [
        {'name': 'get_balance', 'policy': 'supported'},
        {'name': 'subscribe', 'policy': 'supported'},
        {'name': 'wallet.get_balance', 'policy': 'unknown'},
        {'name': 'build_transaction', 'policy': 'notPrefetchable'},
        {'name': 'get_tracked_assets', 'policy': 'supported'},
        {'name': 'track_asset', 'policy': 'unsupported'},
        {'name': 'untrack_asset', 'policy': 'unsupported'},
        {'name': 'sign_data', 'policy': 'unsupported'},
      ]);
      expect(record.containsKey('validation'), isFalse);
      expect(record.containsKey('decision'), isFalse);
      expect(
        diagnostic.format(XswdDiagnosticEvent.received),
        isNot(contains('SENSITIVE')),
      );
      final selected = diagnostic.format(
        XswdDiagnosticEvent.decision,
        grantedPermissions: ['get_balance', 'SENSITIVE_NOT_REQUESTED'],
      );
      final selectedMethods = (jsonDecode(selected) as Map)['methods'] as List;
      expect(selectedMethods.first['selected'], isTrue);
      expect(selectedMethods[1]['selected'], isFalse);
      expect(selected, isNot(contains('SENSITIVE')));
    },
  );

  test(
    'bounds names, list lengths, omitted counts and every serialized record',
    () {
      final names = List<String>.generate(10000, (_) => 'm${'a' * 63}');
      final diagnostic = XswdDiagnosticRequest.inspect(
        _request({'permissions': names}),
      );
      for (final event in XswdDiagnosticEvent.values) {
        final text = diagnostic.format(
          event,
          validation: XswdDiagnosticValidation.failed,
          decision: XelisXswdDecision.alwaysReject,
          disposition: XswdDiagnosticDisposition.validationFailed,
          grantedPermissions: names,
        );
        final record = jsonDecode(text) as Map<String, dynamic>;
        expect(utf8.encode(text).length, lessThanOrEqualTo(8192));
        final methods = record['methods'] as List;
        expect(methods.length, lessThanOrEqualTo(64));
        expect(record['omitted'], names.length - methods.length);
      }
    },
  );

  test('invalid names and scalar types use a fixed marker', () {
    final diagnostic = XswdDiagnosticRequest.inspect(
      _request({
        'permissions': [
          'get_balance\n',
          'a\u001b[31m',
          'a\u0000b',
          'mÃ©thode',
          'a' * 65,
          '',
          {'method': 'SENSITIVE_NESTED'},
          12,
        ],
      }),
    );
    final text = diagnostic.format(XswdDiagnosticEvent.received);
    final record = jsonDecode(text) as Map<String, dynamic>;
    expect(
      record['methods'],
      List.filled(8, {'name': '[invalid-method]', 'policy': 'invalidName'}),
    );
    expect(record['malformedFields'], isTrue);
    expect(text, isNot(contains('SENSITIVE')));
    expect(text, isNot(contains('31m')));
  });

  test(
    'malformed payloads do not traverse nested permission or parameter fields',
    () {
      for (final payload in <Object?>[
        null,
        [],
        'SENSITIVE_PAYLOAD',
        {
          'permissions': 'SENSITIVE_PERMISSION',
          'params': {
            'permissions': ['SENSITIVE_NESTED'],
          },
        },
      ]) {
        final diagnostic = XswdDiagnosticRequest.inspect(_request(payload));
        final text = diagnostic.format(
          XswdDiagnosticEvent.validation,
          validation: XswdDiagnosticValidation.failed,
        );
        final record = jsonDecode(text) as Map<String, dynamic>;
        expect(record['malformedFields'], isTrue);
        expect(record['methods'], isEmpty);
        expect(text, isNot(contains('SENSITIVE')));
      }
      final permission = XswdDiagnosticRequest.inspect(
        _request({
          'method': 'get_balance',
          'params': {
            'private_key': 'SENSITIVE_KEY',
            'method': 'SENSITIVE_PARAMETER',
          },
        }, kind: XelisXswdRequestKind.permission),
      );
      expect(
        jsonDecode(permission.format(XswdDiagnosticEvent.received))['methods'],
        [
          {'name': 'get_balance', 'policy': 'supported'},
        ],
      );
      expect(
        permission.format(XswdDiagnosticEvent.received),
        isNot(contains('SENSITIVE')),
      );
    },
  );

  test(
    'Talker emission obeys the debug and explicit diagnostic gates (debug=$kDebugMode)',
    () {
      expect(
        diagnosticLoggingEnabled,
        kDebugMode &&
            const bool.fromEnvironment(
              'GENESIX_DIAGNOSTICS',
              defaultValue: true,
            ),
      );
      final diagnostic = XswdDiagnosticRequest.inspect(
        _request({
          'permissions': ['subscribe'],
        }),
      );
      final before = talker.history
          .where((entry) => entry.key == xswdDiagnosticLogKey)
          .length;
      diagnostic.record(
        XswdDiagnosticEvent.decision,
        validation: XswdDiagnosticValidation.failed,
        decision: XelisXswdDecision.reject,
        disposition: XswdDiagnosticDisposition.validationFailed,
      );
      final after = talker.history
          .where((entry) => entry.key == xswdDiagnosticLogKey)
          .toList();
      expect(after.length, before + (diagnosticLoggingEnabled ? 1 : 0));
      if (diagnosticLoggingEnabled) {
        final record = jsonDecode(after.last.message!) as Map<String, dynamic>;
        expect(record['request'], diagnostic.correlation);
        expect(record['validation'], 'failed');
        expect(record['decision'], 'reject');
        expect(after.last.message, isNot(contains('SENSITIVE')));
      }
    },
  );
}

XelisXswdRequest _request(
  Object? payload, {
  XelisXswdRequestKind kind = XelisXswdRequestKind.prefetchPermissions,
}) => XelisXswdRequest(
  kind: kind,
  application: XelisXswdApplication(
    id: 'SENSITIVE_ID',
    name: 'SENSITIVE_APP',
    description: 'SENSITIVE_DESCRIPTION',
    url: 'https://SENSITIVE_URL',
    permissions: const {},
    isRelayer: false,
  ),
  payload: xswdTestPayload(payload),
);
