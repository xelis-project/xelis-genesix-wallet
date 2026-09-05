import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/domain/xswd_rpc_budget.dart';

void main() {
  for (final bits in [8, 16, 32, 64, 128, 256]) {
    test('u$bits canonical maximum is exact and overflow is rejected', () {
      final max = (BigInt.one << bits) - BigInt.one;
      expect(parseXswdUnsignedInteger(max.toString(), bits: bits), max);
      expect(parseXswdUnsignedInteger(max, bits: bits), max);
      expect(
        () =>
            parseXswdUnsignedInteger((max + BigInt.one).toString(), bits: bits),
        throwsFormatException,
      );
      expect(
        () => validateXswdRpcParameterBudget([
          _primitive('u$bits', '9' * (2 * 1024 * 1024)),
        ]),
        throwsFormatException,
      );
    });
  }

  for (final invalid in [
    '',
    '00',
    '+1',
    '-1',
    '0x10',
    '1.0',
    '1e2',
    ' 1',
    '١',
  ]) {
    test(
      'rejects non-canonical decimal ${invalid.isEmpty ? "empty" : invalid}',
      () {
        expect(() => parseXswdUnsignedInteger(invalid), throwsFormatException);
      },
    );
  }

  test('burn review rejects long amount, fee and nonce before SDK parsing', () {
    final hostile = '9' * (2 * 1024 * 1024);
    for (final params in <Map<String, dynamic>>[
      {
        'burn': {'asset': 'asset', 'amount': hostile},
      },
      {
        'burn': {'asset': 'asset', 'amount': BigInt.one},
        'nonce': hostile,
      },
      {
        'burn': {'asset': 'asset', 'amount': BigInt.one},
        'fee': {'fixed': hostile},
      },
    ]) {
      expect(
        () => XswdPermissionReview.parse(
          PermissionRpcRequest(
            jsonrpc: '2.0',
            method: 'build_transaction',
            params: params,
          ),
        ),
        throwsFormatException,
      );
    }
  });

  test('invoke review applies the budget before SDK hex decoding', () {
    expect(
      () => XswdPermissionReview.parse(
        PermissionRpcRequest(
          jsonrpc: '2.0',
          method: 'build_transaction',
          params: {
            'invoke_contract': {
              'contract': 'contract',
              'max_gas': BigInt.one,
              'entry_id': 0,
              'parameters': [_bytes(maxXswdRpcScalarBytes + 1)],
            },
          },
        ),
      ),
      throwsFormatException,
    );
  });

  test('decoded bytes budget is aggregate across nested map cells', () {
    validateXswdRpcParameterBudget([_bytes(maxXswdRpcScalarBytes)]);
    expect(
      () => validateXswdRpcParameterBudget([
        {
          'type': 'map',
          'value': [
            [
              _bytes(maxXswdRpcScalarBytes ~/ 2),
              {
                'type': 'object',
                'value': [_bytes(maxXswdRpcScalarBytes ~/ 2 + 1)],
              },
            ],
          ],
        },
      ]),
      throwsFormatException,
    );
  });

  test('UTF-8 string bytes share the budget with bytes and integers', () {
    validateXswdRpcParameterBudget([
      _primitive('string', '😀' * (maxXswdRpcScalarBytes ~/ 4)),
    ]);
    expect(
      () => validateXswdRpcParameterBudget([
        _primitive('string', '😀' * (maxXswdRpcScalarBytes ~/ 4)),
        _primitive('u8', 1),
      ]),
      throwsFormatException,
    );
    expect(
      () => validateXswdRpcParameterBudget([
        _bytes(maxXswdRpcScalarBytes - 1),
        _primitive('string', 'é'),
      ]),
      throwsFormatException,
    );
  });

  test('nested range integers are checked before SDK recursion', () {
    expect(
      () => validateXswdRpcParameterBudget([
        _primitive('range', [
          {'type': 'u128', 'value': '9' * 100000},
          {'type': 'u128', 'value': '1'},
        ]),
      ]),
      throwsFormatException,
    );
  });

  test('structure remains bounded before decoding', () {
    expect(
      () => validateXswdRpcParameterBudget(
        List.generate(4097, (_) => _primitive('null', null)),
      ),
      throwsFormatException,
    );
    Object cell = _primitive('null', null);
    for (var level = 0; level < 65; level++) {
      cell = {
        'type': 'object',
        'value': [cell],
      };
    }
    expect(() => validateXswdRpcParameterBudget([cell]), throwsFormatException);
  });
}

Map<String, dynamic> _primitive(String type, Object? value) => {
  'type': 'primitive',
  'value': {'type': type, 'value': value},
};

Map<String, dynamic> _bytes(int length) => {
  'type': 'bytes',
  'value': '00' * length,
};
