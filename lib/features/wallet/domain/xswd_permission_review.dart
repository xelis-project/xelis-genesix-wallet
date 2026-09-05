import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_rpc_budget.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _maxXswdReviewDepth = 64;
const _maxXswdReviewNodes = 300000;
const _maxXswdReviewStringCharacters = 2 * 1024 * 1024;
const _maxXswdRpcValueCells = 4096;
const _maxXswdOpaqueAddresses = 64;
final _maxU64 = (BigInt.one << 64) - BigInt.one;

final class XswdPermissionReview {
  const XswdPermissionReview({
    required this.request,
    required this.method,
    required this.policy,
    this.buildTransactionParams,
    this.parsedInvokeParameters = const [],
    this.transferDestinations = const [],
  });

  factory XswdPermissionReview.parse(PermissionRpcRequest request) {
    final method = _resolveWalletMethod(request.method);
    final policy = xswdMethodPolicy(method);
    switch (policy.support) {
      case XswdMethodSupport.unsupported:
        throw const FormatException(
          'Unsupported XSWD permission without dedicated review.',
        );
      case XswdMethodSupport.standardReview:
        return XswdPermissionReview(
          request: request,
          method: method,
          policy: policy,
        );
      case XswdMethodSupport.dedicatedTransactionReview:
        break;
    }
    if (method != WalletMethod.buildTransaction) {
      throw StateError('Invalid dedicated XSWD review policy.');
    }

    final params = request.params;
    if (params == null || params.isEmpty) {
      throw const FormatException('Missing build_transaction parameters.');
    }
    _validateReviewBudget(params);
    const commonKeys = {
      'fee',
      'base_fee',
      'fee_limit',
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
    _validateRawBuildTransaction(params, presentTransactionKeys.single);

    final BuildTransactionParams buildParams;
    try {
      buildParams = BuildTransactionParams.fromJson(params);
    } catch (error) {
      throw FormatException('Invalid build_transaction parameters.', error);
    }
    if (buildParams.signers.isNotEmpty) {
      throw const FormatException(
        'Explicit build_transaction signers are not supported.',
      );
    }
    if (!_hasReviewableFees(buildParams)) {
      throw const FormatException('Unsupported build_transaction fee value.');
    }
    final builder = buildParams.transactionTypeBuilder;
    if (!_isReviewableBuilder(builder)) {
      throw const FormatException(
        'Unsupported build_transaction transaction type.',
      );
    }

    final parsedInvokeParameters = <RpcValueCell>[];
    final transferDestinations = <XelisAddressDescriptor>[];
    if (builder is TransfersBuilder) {
      transferDestinations.addAll(_parseTransferDestinations(builder));
    }
    if (builder is InvokeContractBuilder) {
      if (builder.permission is! NoInterContractPermission) {
        throw const FormatException(
          'Unsupported invoke_contract permission field.',
        );
      }
      parsedInvokeParameters.addAll(builder.parameters);
      if (!_areReviewableValues(parsedInvokeParameters)) {
        throw const FormatException(
          'Unsupported invoke_contract parameter value.',
        );
      }
    }

    return XswdPermissionReview(
      request: request,
      method: method,
      policy: policy,
      buildTransactionParams: buildParams,
      parsedInvokeParameters: List.unmodifiable(parsedInvokeParameters),
      transferDestinations: List.unmodifiable(transferDestinations),
    );
  }

  final PermissionRpcRequest request;
  final WalletMethod method;
  final XswdMethodPolicy policy;
  final BuildTransactionParams? buildTransactionParams;
  final List<RpcValueCell> parsedInvokeParameters;
  final List<XelisAddressDescriptor> transferDestinations;

  bool get canPersist => policy.canPersist;

  bool get isBuildTransaction => method == WalletMethod.buildTransaction;
}

List<XelisAddressDescriptor> _parseTransferDestinations(
  TransfersBuilder builder,
) {
  final descriptors = <XelisAddressDescriptor>[];
  for (final transfer in builder.transfers) {
    final XelisAddressDescriptor descriptor;
    try {
      descriptor = XelisWalletFlutter.parseAddress(
        address: transfer.destination,
      );
    } catch (_) {
      throw const FormatException('Invalid transfer destination.');
    }
    if (descriptor.encodedAddress != transfer.destination) {
      throw const FormatException('Non-canonical transfer destination.');
    }
    if (descriptor.isIntegrated && transfer.extraData != null) {
      throw const FormatException(
        'A transfer cannot combine an integrated address and separate attached data.',
      );
    }
    descriptors.add(descriptor);
  }
  return descriptors;
}

List<WalletMethod> resolveXswdPrefetchPermissions(
  PrefetchPermissionsRequest request,
) {
  if (request.permissions.isEmpty ||
      request.permissions.length > WalletMethod.values.length) {
    throw const FormatException('Invalid prefetch permission count.');
  }
  if (request.permissions.toSet().length != request.permissions.length) {
    throw const FormatException('Duplicate prefetch permission.');
  }

  final methods = request.permissions
      .map(_resolveWalletMethod)
      .toList(growable: false);
  if (methods.any((method) => !xswdMethodPolicy(method).canPrefetch)) {
    throw const FormatException(
      'Unsupported XSWD permission cannot be prefetched.',
    );
  }

  return List.unmodifiable(methods);
}

WalletMethod _resolveWalletMethod(String jsonKey) {
  return tryResolveXswdWalletMethod(jsonKey) ??
      (throw const FormatException('Unknown XSWD wallet method.'));
}

bool _hasReviewableFees(BuildTransactionParams params) {
  final feeIsReviewable = switch (params.fee) {
    FixedFeeBuilder(:final amount) => _isU64(amount),
    ExtraFeeBuilder(:final mode) => switch (mode) {
      NoExtraFee() => true,
      TipExtraFee(:final amount) => _isU64(amount),
      MultiplierExtraFee(:final multiplier) =>
        multiplier.isFinite && multiplier >= 0,
    },
  };
  final baseFeeIsReviewable = switch (params.baseFee) {
    NoBaseFee() => true,
    FixedBaseFee(:final amount) ||
    CappedBaseFee(:final amount) => _isU64(amount),
  };
  return feeIsReviewable &&
      baseFeeIsReviewable &&
      (params.feeLimit == null || _isU64(params.feeLimit!)) &&
      (params.nonce == null || _isU64(params.nonce!)) &&
      (params.txVersion == null ||
          (params.txVersion! >= 0 && params.txVersion! <= 3));
}

bool _isReviewableBuilder(TransactionTypeBuilder builder) {
  return switch (builder) {
    TransfersBuilder(:final transfers) =>
      transfers.isNotEmpty &&
          transfers.length <= 255 &&
          transfers.every(
            (transfer) =>
                transfer.asset.isNotEmpty &&
                transfer.destination.isNotEmpty &&
                _isU64(transfer.amount),
          ),
    BurnBuilder(:final asset, :final amount) =>
      asset.isNotEmpty && _isU64(amount),
    MultisigBuilder(:final threshold, :final participants) =>
      participants.isNotEmpty &&
          participants.length <= 255 &&
          participants.every((participant) => participant.isNotEmpty) &&
          threshold > 0 &&
          threshold <= 255 &&
          threshold <= participants.length,
    InvokeContractBuilder(
      :final contract,
      :final maxGas,
      :final entryId,
      :final deposits,
    ) =>
      contract.isNotEmpty &&
          _isU64(maxGas) &&
          entryId >= 0 &&
          entryId <= 65535 &&
          _hasReviewableDeposits(deposits),
    DeployContractBuilder(:final invoke) =>
      invoke == null ||
          (_isU64(invoke.maxGas) && _hasReviewableDeposits(invoke.deposits)),
    BlobBuilder() => false,
  };
}

bool _hasReviewableDeposits(Map<String, ContractDepositBuilder> deposits) =>
    deposits.length <= 255 &&
    deposits.entries.every(
      (entry) => entry.key.isNotEmpty && _isU64(entry.value.amount),
    );

bool _isU64(BigInt value) => value >= BigInt.zero && value <= _maxU64;

void _validateReviewBudget(Object? root) {
  final pending = <({Object? value, int depth})>[(value: root, depth: 0)];
  var nodeCount = 0;
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    nodeCount++;
    if (nodeCount > _maxXswdReviewNodes ||
        current.depth > _maxXswdReviewDepth) {
      throw const FormatException('build_transaction review budget exceeded.');
    }
    switch (current.value) {
      case final String value
          when value.length > _maxXswdReviewStringCharacters:
        throw const FormatException(
          'build_transaction review budget exceeded.',
        );
      case final Map<dynamic, dynamic> value:
        for (final entry in value.entries) {
          pending.add((value: entry.key, depth: current.depth + 1));
          pending.add((value: entry.value, depth: current.depth + 1));
        }
      case final List<dynamic> value:
        for (final entry in value) {
          pending.add((value: entry, depth: current.depth + 1));
        }
    }
  }
}

void _validateRawBuildTransaction(
  Map<String, dynamic> params,
  String transactionKey,
) {
  if (params.containsKey('fee')) _validateRawFee(params['fee']);
  if (params.containsKey('base_fee')) {
    _validateRawBaseFee(params['base_fee']);
  }
  for (final key in const {'fee_limit', 'nonce'}) {
    if (params.containsKey(key)) _requireNonNegativeInteger(params[key]);
  }
  if (params.containsKey('tx_version')) {
    _requireBoundedInt(params['tx_version'], max: 3);
  }
  for (final key in const {'broadcast', 'tx_as_hex'}) {
    if (params.containsKey(key) && params[key] is! bool) {
      throw const FormatException('Invalid build_transaction field value.');
    }
  }
  if (params.containsKey('signers')) {
    final signers = params['signers'];
    if (signers is! List || signers.isNotEmpty) {
      throw const FormatException(
        'Explicit build_transaction signers are not supported.',
      );
    }
  }

  switch (transactionKey) {
    case 'transfers':
      _validateRawTransfers(params[transactionKey]);
      break;
    case 'burn':
      final burn = _requireObject(params[transactionKey]);
      _requireExactKeys(burn, const {'asset', 'amount'});
      _requireNonEmptyString(burn['asset']);
      _requireNonNegativeInteger(burn['amount']);
      break;
    case 'multi_sig':
      final multisig = _requireObject(params[transactionKey]);
      _requireExactKeys(multisig, const {'threshold', 'participants'});
      final threshold = _requireBoundedInt(multisig['threshold'], max: 255);
      final participants = multisig['participants'];
      if (participants is! List ||
          participants.isEmpty ||
          participants.length > 255 ||
          participants.any((participant) => !_isNonEmptyString(participant)) ||
          threshold == 0 ||
          threshold > participants.length) {
        throw const FormatException('Invalid multisig builder value.');
      }
      break;
    case 'invoke_contract':
      _validateRawInvoke(params[transactionKey]);
      break;
    case 'deploy_contract':
      final deploy = _requireObject(params[transactionKey]);
      _requireExactKeys(deploy, const {'contract', 'invoke'});
      _requireNonEmptyString(deploy['contract']);
      if (deploy['invoke'] case final invoke?) {
        _validateRawDeployInvoke(invoke);
      }
      break;
    case 'blob':
      throw const FormatException(
        'Unsupported build_transaction transaction type.',
      );
  }
}

void _validateRawFee(Object? value) {
  final fee = _requireObject(value);
  if (fee.length != 1) {
    throw const FormatException('Invalid build_transaction fee value.');
  }
  if (fee.containsKey('fixed')) {
    _requireNonNegativeInteger(fee['fixed']);
    return;
  }
  if (!fee.containsKey('extra')) {
    throw const FormatException('Invalid build_transaction fee value.');
  }
  final extra = fee['extra'];
  if (extra == 'none') return;
  final mode = _requireObject(extra);
  if (mode.length != 1) {
    throw const FormatException('Invalid build_transaction fee value.');
  }
  if (mode.containsKey('tip')) {
    _requireNonNegativeInteger(mode['tip']);
    return;
  }
  final multiplier = mode['multiplier'];
  if (mode.containsKey('multiplier') &&
      multiplier is num &&
      multiplier.isFinite &&
      multiplier >= 0) {
    return;
  }
  throw const FormatException('Invalid build_transaction fee value.');
}

void _validateRawBaseFee(Object? value) {
  if (value == 'none') return;
  final baseFee = _requireObject(value);
  if (baseFee.length != 1 ||
      (!baseFee.containsKey('fixed') && !baseFee.containsKey('cap'))) {
    throw const FormatException('Invalid build_transaction base fee value.');
  }
  _requireNonNegativeInteger(baseFee.values.single);
}

void _validateRawTransfers(Object? value) {
  if (value is! List || value.isEmpty || value.length > 255) {
    throw const FormatException('Invalid transfer builder value.');
  }
  for (final rawTransfer in value) {
    final transfer = _requireObject(rawTransfer);
    _requireExactKeys(transfer, const {
      'asset',
      'amount',
      'destination',
      'encrypt_extra_data',
      'extra_data',
    });
    _requireNonEmptyString(transfer['asset']);
    _requireNonNegativeInteger(transfer['amount']);
    _requireNonEmptyString(transfer['destination']);
    if (transfer.containsKey('encrypt_extra_data') &&
        transfer['encrypt_extra_data'] is! bool) {
      throw const FormatException('Invalid transfer builder value.');
    }
  }
}

void _validateRawInvoke(Object? value) {
  final invoke = _requireObject(value);
  _requireExactKeys(invoke, const {
    'contract',
    'max_gas',
    'entry_id',
    'parameters',
    'deposits',
    'permission',
  });
  _requireNonEmptyString(invoke['contract']);
  _requireNonNegativeInteger(invoke['max_gas']);
  _requireBoundedInt(invoke['entry_id'], max: 65535);
  if (invoke['parameters'] is! List) {
    throw const FormatException('Invalid invoke_contract builder value.');
  }
  validateXswdRpcParameterBudget(invoke['parameters'] as List<dynamic>);
  if (invoke.containsKey('deposits')) {
    _validateRawDeposits(invoke['deposits']);
  }
  if (invoke.containsKey('permission') && invoke['permission'] != 'none') {
    throw const FormatException(
      'Unsupported invoke_contract permission field.',
    );
  }
}

void _validateRawDeployInvoke(Object? value) {
  final invoke = _requireObject(value);
  _requireExactKeys(invoke, const {'max_gas', 'deposits'});
  _requireNonNegativeInteger(invoke['max_gas']);
  if (invoke.containsKey('deposits')) {
    _validateRawDeposits(invoke['deposits']);
  }
}

void _validateRawDeposits(Object? value) {
  final deposits = _requireObject(value);
  if (deposits.length > 255) {
    throw const FormatException('Invalid contract deposit value.');
  }
  for (final entry in deposits.entries) {
    _requireNonEmptyString(entry.key);
    final deposit = _requireObject(entry.value);
    _requireExactKeys(deposit, const {'amount', 'private'});
    _requireNonNegativeInteger(deposit['amount']);
    if (deposit.containsKey('private') && deposit['private'] is! bool) {
      throw const FormatException('Invalid contract deposit value.');
    }
  }
}

Map<String, dynamic> _requireObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Invalid build_transaction object value.');
}

void _requireExactKeys(Map<String, dynamic> value, Set<String> allowedKeys) {
  if (value.keys.any((key) => !allowedKeys.contains(key))) {
    throw const FormatException('Unsupported nested build_transaction field.');
  }
}

BigInt _requireNonNegativeInteger(Object? value) =>
    parseXswdUnsignedInteger(value);

int _requireBoundedInt(Object? value, {required int max}) {
  if (value is! int || value < 0 || value > max) {
    throw const FormatException('Invalid build_transaction integer value.');
  }
  return value;
}

bool _isNonEmptyString(Object? value) => value is String && value.isNotEmpty;

void _requireNonEmptyString(Object? value) {
  if (!_isNonEmptyString(value)) {
    throw const FormatException('Invalid build_transaction string value.');
  }
}

bool _areReviewableValues(Iterable<RpcValueCell> roots) {
  final pending = <Object>[...roots];
  var cellCount = 0;
  var opaqueAddressCount = 0;
  while (pending.isNotEmpty) {
    final value = pending.removeLast();
    switch (value) {
      case RpcPrimitiveValueCell(:final value, :final extraFields):
        cellCount++;
        if (!extraFields.isEmpty) return false;
        pending.add(value);
      case RpcBytesValueCell(:final extraFields):
        cellCount++;
        if (!extraFields.isEmpty) return false;
      case RpcObjectValueCell(:final values, :final extraFields):
        cellCount++;
        if (!extraFields.isEmpty) return false;
        pending.addAll(values);
      case RpcMapValueCell(:final entries, :final extraFields):
        cellCount++;
        if (!extraFields.isEmpty) return false;
        for (final entry in entries) {
          pending.add(entry.key);
          pending.add(entry.value);
        }
      case RpcUnknownValueCell():
        return false;
      case RpcNullPrimitive(:final extraFields) ||
          RpcBooleanPrimitive(:final extraFields) ||
          RpcU8Primitive(:final extraFields) ||
          RpcU16Primitive(:final extraFields) ||
          RpcU32Primitive(:final extraFields) ||
          RpcU64Primitive(:final extraFields) ||
          RpcU128Primitive(:final extraFields) ||
          RpcU256Primitive(:final extraFields) ||
          RpcStringPrimitive(:final extraFields):
        if (!extraFields.isEmpty) return false;
      case RpcRangePrimitive(:final start, :final end, :final extraFields):
        if (!extraFields.isEmpty) return false;
        pending.add(start);
        pending.add(end);
      case RpcOpaquePrimitive(:final value, :final extraFields):
        if (!extraFields.isEmpty || !_isReviewableOpaque(value)) return false;
        if (value.type == 'Address') {
          opaqueAddressCount++;
          if (opaqueAddressCount > _maxXswdOpaqueAddresses) return false;
        }
      case RpcUnknownPrimitive():
        return false;
    }
    if (cellCount > _maxXswdRpcValueCells) return false;
  }
  return true;
}

bool _isReviewableOpaque(RpcOpaqueValue opaque) {
  if (!opaque.extraFields.isEmpty || opaque.value is! RpcJsonString) {
    return false;
  }
  final value = (opaque.value as RpcJsonString).value;
  return switch (opaque.type) {
    'Address' => _isCanonicalXelisAddress(value),
    'Hash' => value.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(value),
    _ => false,
  };
}

bool _isCanonicalXelisAddress(String value) {
  try {
    XelisWalletFlutter.parseAddress(address: value);
    return true;
  } on Object {
    return false;
  }
}
