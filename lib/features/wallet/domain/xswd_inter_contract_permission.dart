import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

final _contractHashPattern = RegExp(r'^[0-9a-fA-F]{64}$');

bool isXswdContractHash(Object? value) =>
    value is String &&
    value.length == 64 &&
    _contractHashPattern.hasMatch(value);

/// Validate before SDK decoding can discard fields or canonicalize a value.
void validateRawXswdInterContractPermission(Object? value) {
  if (value == 'none' || value == 'all') return;
  final rule = _permissionObject(value);
  if (rule.length != 1 ||
      (!rule.containsKey('specific') && !rule.containsKey('exclude'))) {
    throw const FormatException('Invalid inter-contract permission.');
  }
  final calls = _permissionList(rule.values.single);
  final contracts = <String>{};
  for (final value in calls) {
    final call = _permissionObject(value);
    if (call.length != 2 ||
        !call.containsKey('contract') ||
        !call.containsKey('chunk')) {
      throw const FormatException('Invalid inter-contract call rule.');
    }
    _validateContractHash(call['contract'], contracts);
    final selector = call['chunk'];
    if (selector == 'all') continue;
    final chunks = _permissionObject(selector);
    if (chunks.length != 1 ||
        (!chunks.containsKey('specific') && !chunks.containsKey('exclude'))) {
      throw const FormatException('Invalid inter-contract function selector.');
    }
    _validateChunks(_permissionList(chunks.values.single));
  }
}

/// Typed validation also protects callers constructing SDK values directly.
void validateXswdInterContractPermission(InterContractPermission permission) {
  final calls = switch (permission) {
    NoInterContractPermission() ||
    AllInterContractPermission() => const <ContractCall>[],
    SpecificInterContractPermission(:final calls) ||
    ExcludedInterContractPermission(:final calls) => calls,
    UnknownInterContractPermission() => throw const FormatException(
      'Unknown inter-contract permission.',
    ),
  };
  if (calls.length > 255) {
    throw const FormatException('Too many inter-contract call rules.');
  }
  final contracts = <String>{};
  for (final call in calls) {
    if (!call.extraFields.isEmpty) {
      throw const FormatException('Unsupported inter-contract call field.');
    }
    _validateContractHash(call.contract, contracts);
    switch (call.chunk) {
      case AllContractCallChunks():
        break;
      case SpecificContractCallChunks(:final chunks):
      case ExcludedContractCallChunks(:final chunks):
        _validateChunks(chunks);
      case UnknownContractCallChunk():
        throw const FormatException(
          'Unknown inter-contract function selector.',
        );
    }
  }
}

/// Effective permission for the functions of one listed contract.
/// The outer `exclude` negates the whole selector, including inner exclusions.
enum XswdContractFunctionScope { all, none, only, except }

XswdContractFunctionScope xswdContractFunctionScope(
  ContractCallChunk chunk, {
  required bool excluded,
}) => switch (chunk) {
  AllContractCallChunks() =>
    excluded ? XswdContractFunctionScope.none : XswdContractFunctionScope.all,
  SpecificContractCallChunks(:final chunks) when chunks.isEmpty =>
    excluded ? XswdContractFunctionScope.all : XswdContractFunctionScope.none,
  SpecificContractCallChunks() =>
    excluded
        ? XswdContractFunctionScope.except
        : XswdContractFunctionScope.only,
  ExcludedContractCallChunks(:final chunks) when chunks.isEmpty =>
    excluded ? XswdContractFunctionScope.none : XswdContractFunctionScope.all,
  ExcludedContractCallChunks() =>
    excluded
        ? XswdContractFunctionScope.only
        : XswdContractFunctionScope.except,
  UnknownContractCallChunk() => throw const FormatException(
    'Unknown inter-contract function selector.',
  ),
};

Map<String, dynamic> _permissionObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Invalid inter-contract permission object.');
}

List<dynamic> _permissionList(Object? value) {
  if (value is List && value.length <= 255) return value;
  throw const FormatException('Invalid inter-contract permission list.');
}

void _validateContractHash(Object? value, Set<String> contracts) {
  if (!isXswdContractHash(value) ||
      value is! String ||
      !contracts.add(value.toLowerCase())) {
    throw const FormatException('Invalid or duplicate inter-contract hash.');
  }
}

void _validateChunks(List<dynamic> chunks) {
  if (chunks.length > 255) {
    throw const FormatException('Too many inter-contract functions.');
  }
  final seen = <int>{};
  for (final value in chunks) {
    final int chunk;
    if (value is int && value >= 0 && value <= 65535) {
      chunk = value;
    } else if (value is BigInt && !value.isNegative && value.bitLength <= 16) {
      chunk = value.toInt();
    } else {
      throw const FormatException('Invalid inter-contract function.');
    }
    if (!seen.add(chunk)) {
      throw const FormatException('Duplicate inter-contract function.');
    }
  }
}
