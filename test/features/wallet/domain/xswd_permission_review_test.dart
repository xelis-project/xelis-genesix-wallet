import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _canonicalAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';

void main() {
  setUpAll(XelisWalletFlutter.initialize);

  group('XswdPermissionReview', () {
    test('keeps supported wallet-data permissions persistable', () {
      final review = XswdPermissionReview.parse(
        _request(method: WalletMethod.getBalance.jsonKey),
      );

      expect(review.isBuildTransaction, isFalse);
      expect(review.canPersist, isTrue);
      expect(review.policy.effect, XswdMethodEffect.walletData);
    });

    const unsupportedMethods = {
      WalletMethod.rescan,
      WalletMethod.buildTransactionOffline,
      WalletMethod.buildUnsignedTransaction,
      WalletMethod.finalizeUnsignedTransaction,
      WalletMethod.signUnsignedTransaction,
      WalletMethod.signData,
      WalletMethod.clearTxCache,
      WalletMethod.decryptExtraData,
      WalletMethod.decryptCiphertext,
      WalletMethod.setOnlineMode,
      WalletMethod.setOfflineMode,
      WalletMethod.trackAsset,
      WalletMethod.untrackAsset,
      WalletMethod.createOwnershipProof,
      WalletMethod.createBalanceProof,
    };

    for (final method in unsupportedMethods) {
      test('rejects ${method.jsonKey} without a dedicated review', () {
        expect(
          () => XswdPermissionReview.parse(_request(method: method.jsonKey)),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('accepts a lossless transfer and every common review field', () {
      final review = XswdPermissionReview.parse(
        _request(
          method: WalletMethod.buildTransaction.jsonKey,
          params: {
            'transfers': [
              {
                'asset': 'asset-hash',
                'amount': '9007199254740993',
                'destination': _canonicalAddress,
                'encrypt_extra_data': false,
              },
            ],
            'fee': {'fixed': '7'},
            'base_fee': {'cap': '11'},
            'fee_limit': '13',
            'nonce': '9007199254740995',
            'tx_version': 0,
            'broadcast': true,
            'tx_as_hex': false,
          },
        ),
      );

      expect(review.isBuildTransaction, isTrue);
      expect(review.canPersist, isFalse);
      final params = review.buildTransactionParams!;
      final builder = params.transactionTypeBuilder as TransfersBuilder;
      expect(builder.transfers.single.encryptExtraData, isFalse);
      expect(builder.transfers.single.amount, BigInt.parse('9007199254740993'));
      expect(params.nonce, BigInt.parse('9007199254740995'));
      expect(params.fee, isA<FixedFeeBuilder>());
      expect(params.baseFee, isA<CappedBaseFee>());
      expect(params.feeLimit, BigInt.from(13));
      expect(review.transferDestinations, hasLength(1));
      expect(
        review.transferDestinations.single.encodedAddress,
        _canonicalAddress,
      );
      expect(review.transferDestinations.single.isIntegrated, isFalse);
    });

    test('retains exact typed integrated destination data', () {
      final wide = BigInt.parse('9007199254740993');
      final integrated = XelisWalletFlutter.makeIntegratedAddress(
        baseAddress: _canonicalAddress,
        integratedData: XelisDataElement.value(
          XelisDataValue.unsigned(
            type: XelisUnsignedIntegerType.u64,
            value: wide,
          ),
        ),
      );

      final review = XswdPermissionReview.parse(
        _request(
          method: WalletMethod.buildTransaction.jsonKey,
          params: {
            'transfers': [
              {
                'asset': 'asset-hash',
                'amount': 1,
                'destination': integrated.encodedAddress,
              },
            ],
          },
        ),
      );

      expect(review.transferDestinations, [integrated]);
      final data = review.transferDestinations.single.integratedData;
      expect(data, isA<XelisDataValueElement>());
      final typedValue = (data! as XelisDataValueElement).value;
      expect(typedValue, isA<XelisDataUnsigned>());
      expect((typedValue as XelisDataUnsigned).value, wide);
      expect(typedValue.type, XelisUnsignedIntegerType.u64);
    });

    test('rejects an invalid transfer destination without reflecting it', () {
      const invalid = 'xel:sensitive-invalid-destination';
      Object? failure;
      try {
        XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'transfers': [
                {'asset': 'asset-hash', 'amount': 1, 'destination': invalid},
              ],
            },
          ),
        );
      } catch (error) {
        failure = error;
      }

      expect(failure, isA<FormatException>());
      expect(failure.toString(), isNot(contains(invalid)));
    });

    test('rejects integrated destination with separate attached data', () {
      final integrated = XelisWalletFlutter.makeIntegratedAddress(
        baseAddress: _canonicalAddress,
        integratedData: const XelisDataElement.value(
          XelisDataValue.string('integrated'),
        ),
      );

      expect(
        () => XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'transfers': [
                {
                  'asset': 'asset-hash',
                  'amount': 1,
                  'destination': integrated.encodedAddress,
                  'extra_data': 'separate',
                },
              ],
            },
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    for (final feeCase in <String, Map<String, dynamic>>{
      'automatic': {
        'fee': {'extra': 'none'},
        'base_fee': 'none',
      },
      'tip': {
        'fee': {
          'extra': {'tip': '5'},
        },
        'base_fee': {'fixed': '7'},
      },
      'multiplier': {
        'fee': {
          'extra': {'multiplier': 1.5},
        },
        'base_fee': {'cap': '9'},
        'fee_limit': '12',
      },
    }.entries) {
      test('accepts reviewable ${feeCase.key} fees', () {
        final review = XswdPermissionReview.parse(
          _burnRequest(extraParams: feeCase.value),
        );

        expect(review.buildTransactionParams, isNotNull);
      });
    }

    for (final feeCase in <String, Map<String, dynamic>>{
      'negative fixed fee': {
        'fee': {'fixed': '-1'},
      },
      'infinite multiplier': {
        'fee': {
          'extra': {'multiplier': double.infinity},
        },
      },
      'negative base fee': {
        'base_fee': {'fixed': '-1'},
      },
      'negative fee limit': {'fee_limit': '-1'},
      'negative nonce': {'nonce': '-1'},
    }.entries) {
      test('rejects ${feeCase.key}', () {
        expect(
          () => XswdPermissionReview.parse(
            _burnRequest(extraParams: feeCase.value),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('accepts recursively reviewable invoke parameters', () {
      final review = XswdPermissionReview.parse(
        _invokeRequest(
          parameters: [
            {
              'type': 'primitive',
              'value': {'type': 'null'},
            },
            {
              'type': 'primitive',
              'value': {'type': 'boolean', 'value': true},
            },
            {
              'type': 'primitive',
              'value': {'type': 'u8', 'value': 1},
            },
            {
              'type': 'primitive',
              'value': {'type': 'u16', 'value': 2},
            },
            {
              'type': 'primitive',
              'value': {'type': 'u32', 'value': 3},
            },
            {
              'type': 'primitive',
              'value': {'type': 'u64', 'value': '9007199254740993'},
            },
            {
              'type': 'primitive',
              'value': {
                'type': 'u128',
                'value': '340282366920938463463374607431768211455',
              },
            },
            {
              'type': 'primitive',
              'value': {'type': 'u256', 'value': '900719925474099312345'},
            },
            {
              'type': 'primitive',
              'value': {'type': 'string', 'value': 'reviewable'},
            },
            {
              'type': 'primitive',
              'value': {
                'type': 'range',
                'value': [
                  {'type': 'u8', 'value': 1},
                  {'type': 'u8', 'value': 9},
                ],
              },
            },
            {'type': 'bytes', 'value': '00ff'},
            {
              'type': 'object',
              'value': [
                {
                  'type': 'primitive',
                  'value': {'type': 'null'},
                },
              ],
            },
            {
              'type': 'map',
              'value': [
                [
                  {
                    'type': 'primitive',
                    'value': {'type': 'string', 'value': 'key'},
                  },
                  {'type': 'bytes', 'value': '00ff'},
                ],
              ],
            },
            {
              'type': 'primitive',
              'value': {
                'type': 'opaque',
                'value': {'type': 'Hash', 'value': List.filled(64, '0').join()},
              },
            },
            {
              'type': 'primitive',
              'value': {
                'type': 'opaque',
                'value': {'type': 'Address', 'value': _canonicalAddress},
              },
            },
          ],
          permission: 'none',
        ),
      );

      expect(review.parsedInvokeParameters, hasLength(15));
      expect(review.parsedInvokeParameters.first, isA<RpcPrimitiveValueCell>());
      final builder =
          review.buildTransactionParams!.transactionTypeBuilder
              as InvokeContractBuilder;
      expect(builder.maxGas, BigInt.parse('9007199254740993'));
    });

    for (final invalidParameter in <String, Map<String, dynamic>>{
      'unknown cell': {'type': 'future', 'value': 1},
      'unknown primitive': {
        'type': 'primitive',
        'value': {'type': 'future', 'value': 1},
      },
      'additive field': {'type': 'bytes', 'value': '00', 'future': true},
      'unknown opaque': {
        'type': 'primitive',
        'value': {
          'type': 'opaque',
          'value': {'type': 'Future', 'value': 'opaque'},
        },
      },
      'invalid opaque hash': {
        'type': 'primitive',
        'value': {
          'type': 'opaque',
          'value': {'type': 'Hash', 'value': '00'},
        },
      },
      'empty opaque address': {
        'type': 'primitive',
        'value': {
          'type': 'opaque',
          'value': {'type': 'Address', 'value': ''},
        },
      },
      'non-canonical opaque address': {
        'type': 'primitive',
        'value': {
          'type': 'opaque',
          'value': {'type': 'Address', 'value': 'xel:destination'},
        },
      },
    }.entries) {
      test('rejects ${invalidParameter.key} invoke parameter', () {
        expect(
          () => XswdPermissionReview.parse(
            _invokeRequest(parameters: [invalidParameter.value]),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }

    for (final permission in <Object>[
      'all',
      {'specific': <Object>[]},
      {'exclude': <Object>[]},
      'future_permission',
    ]) {
      test('rejects $permission invoke permission without a review', () {
        expect(
          () => XswdPermissionReview.parse(
            _invokeRequest(parameters: const [], permission: permission),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('accepts the serialized contract deployment shape', () {
      final review = XswdPermissionReview.parse(
        _request(
          method: WalletMethod.buildTransaction.jsonKey,
          params: {
            'deploy_contract': {'contract': '00aa'},
          },
        ),
      );

      final builder =
          review.buildTransactionParams!.transactionTypeBuilder
              as DeployContractBuilder;
      expect(builder.contract.value, '00aa');
    });

    test('accepts the maximum u64 builder value and transaction version', () {
      final review = XswdPermissionReview.parse(
        _request(
          method: WalletMethod.buildTransaction.jsonKey,
          params: {
            'burn': {'asset': 'asset-hash', 'amount': '18446744073709551615'},
            'fee': {'fixed': '18446744073709551615'},
            'fee_limit': '18446744073709551615',
            'nonce': '18446744073709551615',
            'tx_version': 3,
          },
        ),
      );

      expect(review.buildTransactionParams, isNotNull);
    });

    for (final invalid in <String, Map<String, dynamic>>{
      'amount above u64': {
        'burn': {'asset': 'asset-hash', 'amount': '18446744073709551616'},
      },
      'unknown transaction version': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'tx_version': 4,
      },
      'fractional multisig threshold': {
        'multi_sig': {
          'threshold': 1.5,
          'participants': [_canonicalAddress],
        },
      },
      'negative invoke gas': {
        'invoke_contract': {
          'contract': 'contract-hash',
          'max_gas': -1,
          'entry_id': 0,
          'parameters': <Object>[],
        },
      },
    }.entries) {
      test('rejects ${invalid.key}', () {
        expect(
          () => XswdPermissionReview.parse(
            _request(
              method: WalletMethod.buildTransaction.jsonKey,
              params: invalid.value,
            ),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }

    for (final additive in <String, Map<String, dynamic>>{
      'transfer': {
        'transfers': [
          {
            'asset': 'asset-hash',
            'amount': 1,
            'destination': _canonicalAddress,
            'future': true,
          },
        ],
      },
      'burn': {
        'burn': {'asset': 'asset-hash', 'amount': 1, 'future': true},
      },
      'multisig': {
        'multi_sig': {
          'threshold': 1,
          'participants': [_canonicalAddress],
          'future': true,
        },
      },
      'invoke': {
        'invoke_contract': {
          'contract': 'contract-hash',
          'max_gas': 1,
          'entry_id': 0,
          'parameters': <Object>[],
          'future': true,
        },
      },
      'invoke deposit': {
        'invoke_contract': {
          'contract': 'contract-hash',
          'max_gas': 1,
          'entry_id': 0,
          'parameters': <Object>[],
          'deposits': {
            'asset-hash': {'amount': 1, 'future': true},
          },
        },
      },
      'deploy': {
        'deploy_contract': {'contract': '00aa', 'future': true},
      },
      'deploy invoke': {
        'deploy_contract': {
          'contract': '00aa',
          'invoke': {'max_gas': 1, 'future': true},
        },
      },
      'deploy deposit': {
        'deploy_contract': {
          'contract': '00aa',
          'invoke': {
            'max_gas': 1,
            'deposits': {
              'asset-hash': {'amount': 1, 'future': true},
            },
          },
        },
      },
    }.entries) {
      test('rejects additive nested ${additive.key} field', () {
        expect(
          () => XswdPermissionReview.parse(
            _request(
              method: WalletMethod.buildTransaction.jsonKey,
              params: additive.value,
            ),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('rejects an excessively deep review payload before SDK parsing', () {
      Object? nested = 'leaf';
      for (var depth = 0; depth < 65; depth++) {
        nested = <String, Object?>{'nested': nested};
      }
      expect(
        () => XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'transfers': [
                {
                  'asset': 'asset-hash',
                  'amount': 1,
                  'destination': _canonicalAddress,
                  'extra_data': nested,
                },
              ],
            },
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an RPC graph above the review cell budget', () {
      final parameters = List<Object?>.generate(
        4097,
        (_) => {
          'type': 'primitive',
          'value': {'type': 'null'},
        },
      );
      expect(
        () =>
            XswdPermissionReview.parse(_invokeRequest(parameters: parameters)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects opaque addresses above the validation budget', () {
      final parameters = List<Object?>.generate(
        65,
        (_) => {
          'type': 'primitive',
          'value': {
            'type': 'opaque',
            'value': {'type': 'Address', 'value': _canonicalAddress},
          },
        },
      );
      expect(
        () =>
            XswdPermissionReview.parse(_invokeRequest(parameters: parameters)),
        throwsA(isA<FormatException>()),
      );
    });

    for (final unsupported in <String, Map<String, dynamic>>{
      'blob': {
        'blob': {'data': 'opaque', 'destinations': <String>[], 'encrypt': true},
      },
      'unknown field': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'future_field': true,
      },
      'explicit signers': {
        'burn': {'asset': 'asset-hash', 'amount': 1},
        'signers': [
          {'id': 0, 'private_key': 'must-not-leak'},
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

    test('does not include explicit signer material in rejection details', () {
      Object? failure;
      try {
        XswdPermissionReview.parse(
          _request(
            method: WalletMethod.buildTransaction.jsonKey,
            params: {
              'burn': {'asset': 'asset-hash', 'amount': 1},
              'signers': [
                {'id': 0, 'private_key': 'sensitive-private-key'},
              ],
            },
          ),
        );
      } catch (error) {
        failure = error;
      }

      expect(failure, isA<FormatException>());
      expect(failure.toString(), isNot(contains('sensitive-private-key')));
    });

    test('rejects unknown, prefixed, and incomplete methods', () {
      expect(
        () => XswdPermissionReview.parse(_request(method: 'future_method')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () =>
            XswdPermissionReview.parse(_request(method: 'wallet.get_balance')),
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

    test('rejects duplicate permissions before building consent widgets', () {
      for (final count in [2, WalletMethod.values.length + 1, 4096]) {
        expect(
          () => resolveXswdPrefetchPermissions(
            PrefetchPermissionsRequest(
              permissions: List.filled(count, 'get_balance'),
            ),
          ),
          throwsFormatException,
        );
      }
    });

    for (final permissions in <List<String>>[
      const [],
      const ['future_method'],
      ...WalletMethod.values
          .where((method) => !xswdMethodPolicy(method).canPrefetch)
          .map((method) => [method.jsonKey]),
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

PermissionRpcRequest _burnRequest({
  Map<String, dynamic> extraParams = const {},
}) {
  return _request(
    method: WalletMethod.buildTransaction.jsonKey,
    params: {
      'burn': {'asset': 'asset-hash', 'amount': '1'},
      ...extraParams,
    },
  );
}

PermissionRpcRequest _invokeRequest({
  required List<Object?> parameters,
  Object permission = 'none',
}) {
  return _request(
    method: WalletMethod.buildTransaction.jsonKey,
    params: {
      'invoke_contract': {
        'contract': 'contract-hash',
        'max_gas': '9007199254740993',
        'entry_id': 0,
        'parameters': parameters,
        'permission': permission,
      },
    },
  );
}

PermissionRpcRequest _request({
  required String method,
  Map<String, dynamic>? params,
}) {
  return PermissionRpcRequest(jsonrpc: '2.0', method: method, params: params);
}
