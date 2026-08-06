import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

void main() {
  group('XswdPermissionReview', () {
    test('keeps non-transaction permissions persistable', () {
      final review = XswdPermissionReview.parse(
        _request(method: WalletMethod.getBalance.jsonKey),
      );

      expect(review.isBuildTransaction, isFalse);
      expect(review.canPersist, isTrue);
    });

    for (final method in <WalletMethod>[
      WalletMethod.buildTransactionOffline,
      WalletMethod.buildUnsignedTransaction,
      WalletMethod.finalizeUnsignedTransaction,
      WalletMethod.signUnsignedTransaction,
      WalletMethod.signData,
    ]) {
      test('rejects ${method.jsonKey} without a dedicated review', () {
        expect(
          () => XswdPermissionReview.parse(_request(method: method.jsonKey)),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('accepts a fully understood transfer for one-time review', () {
      final review = XswdPermissionReview.parse(
        _request(
          method: WalletMethod.buildTransaction.jsonKey,
          params: {
            'transfers': [
              {
                'asset': 'asset-hash',
                'amount': 42,
                'destination': 'xel:destination',
                'extra_data': 'attached-data',
                'encrypt_extra_data': false,
              },
            ],
            'fee': {'Value': 7},
            'nonce': 3,
            'tx_version': 0,
            'broadcast': true,
            'tx_as_hex': false,
          },
        ),
      );

      expect(review.isBuildTransaction, isTrue);
      expect(review.canPersist, isFalse);
      expect(
        review.buildTransactionParams?.transactionTypeBuilder,
        isA<TransfersBuilder>(),
      );
      final builder =
          review.buildTransactionParams!.transactionTypeBuilder
              as TransfersBuilder;
      expect(builder.transfers.single.encryptExtraData, isFalse);
    });

    test('fails closed when lossless integers are unavailable', () {
      expect(
        () => XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'burn': {'asset': 'asset-hash', 'amount': 1},
            },
          ),
          supportsLosslessIntegers: false,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('validates invoke parameters before presentation', () {
      expect(
        () => XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'invoke_contract': {
                'contract': 'contract-hash',
                'max_gas': 1,
                'entry_id': 0,
                'parameters': [<String, dynamic>{}],
              },
            },
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invoke permissions without a dedicated projection', () {
      expect(
        () => XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'invoke_contract': {
                'contract': 'contract-hash',
                'max_gas': 1,
                'entry_id': 0,
                'parameters': <Object?>[],
                'permission': 'deposit',
              },
            },
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    for (final unsupported in <String, Map<String, dynamic>>{
      'blob': {
        'blob': {'data': 'opaque', 'destinations': <String>[]},
      },
      'base_fee': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'base_fee': 1,
      },
      'fee_limit': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'fee_limit': 1,
      },
      'unknown field': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'future_field': true,
      },
      'explicit signers': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'signers': [
          {'Id': 0},
        ],
      },
    }.entries) {
      test('fails closed for unsupported ${unsupported.key}', () {
        expect(
          () => XswdPermissionReview.parse(
            _request(
              method: WalletMethod.buildTransaction.jsonKey,
              params: unsupported.value,
            ),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('rejects unknown methods and missing transaction parameters', () {
      expect(
        () => XswdPermissionReview.parse(_request(method: 'future_method')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => XswdPermissionReview.parse(
          _request(method: WalletMethod.buildTransaction.jsonKey),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('resolveXswdPrefetchPermissions', () {
    test('accepts known non-signing permissions', () {
      final methods = resolveXswdPrefetchPermissions(
        const PrefetchPermissionsRequest(
          permissions: ['get_balance', 'get_address'],
        ),
      );

      expect(methods, [WalletMethod.getBalance, WalletMethod.getAddress]);
    });

    for (final permissions in <List<String>>[
      const [],
      const ['future_method'],
      const ['build_transaction'],
      const ['finalize_unsigned_transaction'],
      const ['sign_unsigned_transaction'],
      const ['sign_data'],
    ]) {
      test('fails closed for prefetch $permissions', () {
        expect(
          () => resolveXswdPrefetchPermissions(
            PrefetchPermissionsRequest(permissions: permissions),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });
}

PermissionRpcRequest _request({
  required String method,
  Map<String, dynamic>? params,
}) =>
    PermissionRpcRequest(id: 1, jsonrpc: '2.0', method: method, params: params);
