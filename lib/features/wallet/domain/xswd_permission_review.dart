import 'package:flutter/foundation.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

final class XswdPermissionReview {
  const XswdPermissionReview({
    required this.request,
    required this.method,
    required this.canPersist,
    this.buildTransactionParams,
    this.parsedInvokeParameters = const [],
  });

  factory XswdPermissionReview.parse(
    PermissionRpcRequest request, {
    bool supportsLosslessIntegers = !kIsWeb,
  }) {
    final method = _resolveWalletMethod(request.method);
    if (method != WalletMethod.buildTransaction) {
      if (isXswdHighRiskMethod(method)) {
        throw const FormatException(
          'Unsupported transaction or signing permission without dedicated review.',
        );
      }
      return XswdPermissionReview(
        request: request,
        method: method,
        canPersist: true,
      );
    }

    if (!supportsLosslessIntegers) {
      throw const FormatException(
        'build_transaction review is unavailable without lossless integers.',
      );
    }

    final params = request.params;
    if (params == null || params.isEmpty) {
      throw const FormatException('Missing build_transaction parameters.');
    }
    if (params.containsKey('base_fee') || params.containsKey('fee_limit')) {
      throw const FormatException('Unsupported build_transaction fee fields.');
    }
    const commonKeys = {
      'fee',
      'nonce',
      'tx_version',
      'broadcast',
      'tx_as_hex',
      'signers',
    };
    const transactionKeys = {
      'transfers',
      'burn',
      'multi_sig',
      'invoke_contract',
      'deploy_contract',
      'blob',
    };
    final presentTransactionKeys = params.keys
        .where(transactionKeys.contains)
        .toList(growable: false);
    if (presentTransactionKeys.length != 1) {
      throw const FormatException(
        'Expected exactly one build_transaction type.',
      );
    }
    final allowedKeys = {...commonKeys, presentTransactionKeys.single};
    if (params.keys.any((key) => !allowedKeys.contains(key))) {
      throw const FormatException('Unsupported build_transaction field.');
    }
    if (params['signers'] case final List<dynamic> signers
        when signers.isNotEmpty) {
      throw const FormatException(
        'Explicit build_transaction signers are not supported.',
      );
    }

    final BuildTransactionParams buildParams;
    try {
      buildParams = BuildTransactionParams.fromJson(params);
    } catch (error) {
      throw FormatException('Invalid build_transaction parameters.', error);
    }
    if (buildParams.signers case final signers? when signers.isNotEmpty) {
      throw const FormatException(
        'Explicit build_transaction signers are not supported.',
      );
    }
    final builder = buildParams.transactionTypeBuilder;
    final supported =
        builder is TransfersBuilder ||
        builder is BurnBuilder ||
        builder is MultisigBuilder ||
        builder is InvokeContractBuilder ||
        builder is DeployContractBuilder;
    if (!supported || builder is BlobBuilder) {
      throw const FormatException(
        'Unsupported build_transaction transaction type.',
      );
    }

    final parsedInvokeParameters = <ParsedValue>[];
    if (builder is InvokeContractBuilder) {
      if (builder.permission != 'none') {
        throw const FormatException(
          'Unsupported invoke_contract permission field.',
        );
      }
      try {
        parsedInvokeParameters.addAll(
          builder.parameters.map(deserializeValueCell),
        );
      } catch (error) {
        throw FormatException('Invalid invoke_contract parameter.', error);
      }
      if (parsedInvokeParameters.any((value) => !_isReviewableValue(value))) {
        throw const FormatException(
          'Unsupported invoke_contract parameter value.',
        );
      }
    }

    return XswdPermissionReview(
      request: request,
      method: method,
      buildTransactionParams: buildParams,
      parsedInvokeParameters: List.unmodifiable(parsedInvokeParameters),
      canPersist: false,
    );
  }

  final PermissionRpcRequest request;
  final WalletMethod method;
  final BuildTransactionParams? buildTransactionParams;
  final List<ParsedValue> parsedInvokeParameters;
  final bool canPersist;

  bool get isBuildTransaction => method == WalletMethod.buildTransaction;
}

List<WalletMethod> resolveXswdPrefetchPermissions(
  PrefetchPermissionsRequest request,
) {
  if (request.permissions.isEmpty) {
    throw const FormatException('Prefetch permissions cannot be empty.');
  }

  final methods = request.permissions
      .map(_resolveWalletMethod)
      .toList(growable: false);
  if (methods.any(isXswdHighRiskMethod)) {
    throw const FormatException(
      'Transaction and signing permissions cannot be prefetched.',
    );
  }

  return List.unmodifiable(methods);
}

const _xswdHighRiskMethods = {
  WalletMethod.buildTransaction,
  WalletMethod.buildTransactionOffline,
  WalletMethod.buildUnsignedTransaction,
  WalletMethod.finalizeUnsignedTransaction,
  WalletMethod.signUnsignedTransaction,
  WalletMethod.signData,
};

bool isXswdHighRiskMethod(WalletMethod method) =>
    _xswdHighRiskMethods.contains(method);

bool isXswdHighRiskMethodKey(String jsonKey) => WalletMethod.values.any(
  (method) => method.jsonKey == jsonKey && isXswdHighRiskMethod(method),
);

WalletMethod _resolveWalletMethod(String jsonKey) {
  for (final method in WalletMethod.values) {
    if (method.jsonKey == jsonKey) return method;
  }
  throw FormatException('Unknown wallet method: $jsonKey');
}

bool _isReviewableValue(ParsedValue value) {
  return switch (value) {
    ParsedPrimitive(:final type) => type != 'unknown',
    ParsedOption(:final isNone) => isNone || _isReviewableValue(value.unwrap()),
    ParsedArray(:final items) => items.every(_isReviewableValue),
    ParsedMap(:final entries) => entries.values.every(
      (entry) => entry is! ParsedValue || _isReviewableValue(entry),
    ),
    _ => false,
  };
}
