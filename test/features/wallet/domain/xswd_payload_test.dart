import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_payload.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

import '../../../helpers/xswd_test_payload.dart';

void main() {
  test(
    'keeps real numeric u64 tokens exact, distinct from strings and floats',
    () {
      final wire = parseBigIntJson(
        '{"wide":9007199254740993,"max":18446744073709551615,'
        '"negative":-9223372036854775808,"text":"9007199254740993",'
        '"float":1.5}',
      );
      final decoded = decodeXswdPayload(xswdTestPayload(wire));
      expect(decoded['wide'], BigInt.parse('9007199254740993'));
      expect(decoded['max'], (BigInt.one << 64) - BigInt.one);
      expect(decoded['negative'], -(BigInt.one << 63));
      expect(decoded['text'], isA<String>());
      expect(decoded['float'], 1.5);
    },
  );

  test('normalizes only bounded SDK fields and exact integer multipliers', () {
    final decoded = decodeXswdPayload(
      xswdTestPayload({
        'method': 'build_transaction',
        'params': {
          'tx_version': 3,
          'invoke_contract': {'entry_id': 65535, 'max_gas': BigInt.one << 60},
          'fee': {
            'extra': {'multiplier': 2},
          },
          'nonce': 1,
          'extra_data': {'entry_id': 7},
        },
      }),
    );
    normalizeXswdBuildTransactionFields(decoded);
    final params = decoded['params'] as Map<String, dynamic>;
    expect(params['tx_version'], 3);
    expect((params['invoke_contract'] as Map)['entry_id'], 65535);
    expect((params['invoke_contract'] as Map)['max_gas'], BigInt.one << 60);
    expect(params['nonce'], BigInt.one);
    expect((params['extra_data'] as Map)['entry_id'], BigInt.from(7));
    expect(((params['fee'] as Map)['extra'] as Map)['multiplier'], 2);
  });

  test('does not narrow an out-of-range SDK field or multiplier', () {
    for (final params in [
      {'tx_version': BigInt.from(4)},
      {
        'multi_sig': {'threshold': BigInt.from(256)},
      },
      {
        'invoke_contract': {'entry_id': BigInt.from(65536)},
      },
      {
        'fee': {
          'extra': {'multiplier': BigInt.one << 64},
        },
      },
    ]) {
      expect(
        () => normalizeXswdBuildTransactionFields({
          'method': 'build_transaction',
          'params': params,
        }),
        throwsFormatException,
      );
    }
  });

  test('correlation IDs stay owned by XWF and never require an int cast', () {
    for (final id in [null, 'opaque-id', (BigInt.one << 64) - BigInt.one]) {
      final decoded = decodeXswdPayload(
        xswdTestPayload({'id': id, 'jsonrpc': '2.0', 'method': 'get_balance'}),
      );
      final request = PermissionRpcRequest.fromJson(decoded);
      expect(request.method, 'get_balance');
      expect(request.toString(), 'PermissionRpcRequest(<redacted>)');
    }
  });

  test('rejects invalid roots, nonfinite values and excessive depth', () {
    expect(() => decodeXswdPayload(null), throwsFormatException);
    expect(
      () => decodeXswdPayload(const XelisXswdStringValue('secret')),
      throwsFormatException,
    );
    expect(
      () => decodeXswdPayload(
        XelisXswdObjectValue({
          'bad': const XelisXswdFloatValue(double.infinity),
        }),
      ),
      throwsFormatException,
    );
    XelisXswdValue nested = const XelisXswdNullValue();
    for (var i = 0; i < 65; i++) {
      nested = XelisXswdArrayValue([nested]);
    }
    expect(
      () => decodeXswdPayload(XelisXswdObjectValue({'deep': nested})),
      throwsFormatException,
    );
  });

  test('rejects oversized text without exposing it in the failure', () {
    final secret = 's' * (2 * 1024 * 1024 + 1);
    expect(
      () => decodeXswdPayload(
        XelisXswdObjectValue({'value': XelisXswdStringValue(secret)}),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString().contains(secret),
          'contains payload',
          isFalse,
        ),
      ),
    );
  });

  test('reviews numeric u64 max through the complete typed SDK boundary', () {
    final payload = xswdTestPayload(
      parseBigIntJson(
        '{"id":18446744073709551615,"jsonrpc":"2.0",'
        '"method":"build_transaction","params":{'
        '"burn":{"asset":"asset-hash","amount":18446744073709551615},'
        '"nonce":18446744073709551615,"fee":{"fixed":18446744073709551615},'
        '"tx_version":3}}',
      ),
    );
    final decoded = decodeXswdPayload(payload);
    normalizeXswdBuildTransactionFields(decoded);
    final review = XswdPermissionReview.parse(
      PermissionRpcRequest.fromJson(decoded),
    );
    final max = (BigInt.one << 64) - BigInt.one;
    expect(
      (review.buildTransactionParams!.transactionTypeBuilder as BurnBuilder)
          .amount,
      max,
    );
    expect(review.buildTransactionParams!.nonce, max);
    expect((review.buildTransactionParams!.fee as FixedFeeBuilder).amount, max);
    expect(review.canPersist, isFalse);
  }, testOn: 'vm');
}
