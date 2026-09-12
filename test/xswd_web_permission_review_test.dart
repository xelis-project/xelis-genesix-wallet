@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

// Keep this browser entrypoint at test/ root: Flutter 3.47.1 inserts Windows
// path separators unescaped into the browser testSelector JavaScript string.
import 'helpers/xswd_test_payload.dart';

final _wide = BigInt.parse('9007199254740993');
final _maximum = BigInt.parse('18446744073709551615');
const _contractA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('Web retains exact burn amount, fee, limit and nonce', () {
    final params = _review({
      'burn': {'asset': 'asset-hash', 'amount': _wide},
    }).buildTransactionParams!;
    expect((params.transactionTypeBuilder as BurnBuilder).amount, _wide);
    expect((params.fee as FixedFeeBuilder).amount, _maximum);
    expect(params.feeLimit, _maximum);
    expect(params.nonce, _wide + BigInt.two);
  });

  test('Web retains exact invocation gas and deposit', () {
    final params = _review({
      'invoke_contract': {
        'contract':
            'abababababababababababababababababababababababababababababababab',
        'max_gas': _wide,
        'entry_id': 0,
        'deposits': {
          'asset-hash': {'amount': _wide, 'private': false},
        },
        'parameters': <Object?>[],
        'permission': 'none',
      },
    }).buildTransactionParams!;
    final builder = params.transactionTypeBuilder as InvokeContractBuilder;
    expect(builder.maxGas, _wide);
    expect(builder.deposits.values.single.amount, _wide);
  });

  test('Web still rejects an integer above the protocol u64 bound', () {
    expect(
      () => _review({
        'burn': {'asset': 'asset-hash', 'amount': _maximum + BigInt.one},
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('Web preserves supported inter-contract permission variants', () {
    final permissions = <Object>[
      'all',
      {
        'specific': [
          {
            'contract': _contractA,
            'chunk': {
              'specific': [1, 65535],
            },
          },
        ],
      },
      {
        'exclude': [
          {
            'contract': _contractA,
            'chunk': {
              'exclude': [2],
            },
          },
        ],
      },
    ];

    for (final permission in permissions) {
      final params = _review({
        'invoke_contract': {
          'contract': _contractA,
          'max_gas': _wide,
          'entry_id': 0,
          'deposits': <String, Object?>{},
          'parameters': <Object?>[],
          'permission': permission,
        },
      }).buildTransactionParams!;
      final builder = params.transactionTypeBuilder as InvokeContractBuilder;
      expect(builder.permission.toJson(), permission);
    }
  });
}

XswdPermissionReview _review(Map<String, Object?> builder) {
  return XswdPermissionReview.parse(
    xswdTestPermission(
      method: 'build_transaction',
      params: {
        ...builder,
        'fee': {'fixed': _maximum},
        'fee_limit': _maximum,
        'nonce': _wide + BigInt.two,
        'tx_version': 0,
        'broadcast': false,
        'tx_as_hex': true,
      },
    ),
  );
}
