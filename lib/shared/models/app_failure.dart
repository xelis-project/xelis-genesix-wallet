import 'dart:math';

import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Version of Genesix's support-safe application failure contract.
abstract final class AppFailureContract {
  static const currentVersion = 1;
}

/// Application-level category used for recovery and user-facing presentation.
///
/// The original package code remains available through [AppFailure.code]. This
/// smaller set expresses only decisions that Genesix currently needs to make.
enum AppFailureCategory {
  invalidInput,
  authenticationOrCorruptData,
  offline,
  networkFailure,
  networkMismatch,
  daemonRejected,
  insufficientFunds,
  conflict,
  operationInProgress,
  notFound,
  unsupported,
  storageFailure,
  serializationFailure,
  cancelled,
  initializationFailure,
  internalFailure,
  unsupportedPlatform,
  nativePanic,
  bridgeFailure,
  operationFailure,
  unexpected,
}

/// Safe, immutable application representation of a wallet failure.
///
/// This model deliberately copies only the support-safe fields exposed by
/// `xelis-wallet-flutter`. It never retains the native exception, its diagnostic
/// message, an arbitrary error object, or a stack trace.
final class AppFailure {
  AppFailure._({
    required this.contractVersion,
    required this.exceptionType,
    required this.source,
    required this.operation,
    required this.code,
    required this.supportId,
    required this.category,
    this.originContractVersion,
    this.nativeKind,
    this.nativeCode,
  });

  factory AppFailure.fromXelis(XelisWalletException error) {
    return AppFailure._(
      contractVersion: AppFailureContract.currentVersion,
      originContractVersion: error.contractVersion,
      exceptionType: error.runtimeType.toString(),
      source: error.source.name,
      operation: error.operation.id,
      code: error.code.id,
      supportId: error.supportId,
      nativeKind: error.nativeKind,
      nativeCode: error.nativeCode,
      category: _categoryForXelisCode(error.code),
    );
  }

  /// Creates a support-safe failure for an error owned by Genesix or another
  /// non-XELIS Dart dependency.
  ///
  /// Callers provide only reviewed identifiers. The original error and its
  /// message are deliberately not accepted, so they cannot leak into Riverpod
  /// state, UI, or retained support logs.
  factory AppFailure.application({
    required String operation,
    required String code,
    required String exceptionType,
    AppFailureCategory category = AppFailureCategory.unexpected,
  }) {
    return AppFailure._(
      contractVersion: AppFailureContract.currentVersion,
      exceptionType: exceptionType,
      source: 'genesix',
      operation: operation,
      code: code,
      supportId: _createApplicationSupportId(),
      category: category,
    );
  }

  final int contractVersion;

  /// Version of the originating structured contract, when one exists.
  ///
  /// This is distinct from [contractVersion], which always versions the
  /// Genesix-owned `AppFailure` schema.
  final int? originContractVersion;
  final String exceptionType;
  final String source;
  final String operation;
  final String code;
  final String supportId;
  final String? nativeKind;
  final int? nativeCode;
  final AppFailureCategory category;

  /// Complete safe reference that a user can include in a support request.
  String get supportReference => '$supportId · $source · $operation · $code';

  @override
  String toString() {
    final nativeKindField = nativeKind == null
        ? ''
        : ', nativeKind=$nativeKind';
    final nativeCodeField = nativeCode == null
        ? ''
        : ', nativeCode=$nativeCode';
    final originContractVersionField = originContractVersion == null
        ? ''
        : ', originContractVersion=$originContractVersion';
    return 'AppFailure('
        'contractVersion=$contractVersion, '
        'exceptionType=$exceptionType, '
        'source=$source, '
        'operation=$operation, '
        'code=$code, '
        'supportId=$supportId'
        '$originContractVersionField'
        '$nativeKindField'
        '$nativeCodeField)';
  }
}

var _fallbackSupportIdCounter = 0;

String _createApplicationSupportId() {
  try {
    final random = Random.secure();
    final hex = List<int>.generate(10, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return _formatApplicationSupportId(hex);
  } catch (_) {
    final timestamp = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(16, '0');
    final counter = (_fallbackSupportIdCounter++)
        .toRadixString(16)
        .padLeft(8, '0');
    final hex = '$timestamp$counter'.substring(4).toUpperCase();
    return _formatApplicationSupportId(hex);
  }
}

String _formatApplicationSupportId(String hex) =>
    'GNX-${hex.substring(0, 4)}-${hex.substring(4, 8)}-'
    '${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
    '${hex.substring(16, 20)}';

AppFailureCategory _categoryForXelisCode(XelisWalletErrorCode code) {
  if (code == XelisWalletErrorCode.invalidInput) {
    return AppFailureCategory.invalidInput;
  }
  if (code == XelisWalletErrorCode.authenticationOrCorruptData) {
    return AppFailureCategory.authenticationOrCorruptData;
  }
  if (code == XelisWalletErrorCode.offline) {
    return AppFailureCategory.offline;
  }
  if (code == XelisWalletErrorCode.networkFailure) {
    return AppFailureCategory.networkFailure;
  }
  if (code == XelisWalletErrorCode.networkMismatch) {
    return AppFailureCategory.networkMismatch;
  }
  if (code == XelisWalletErrorCode.daemonRejected) {
    return AppFailureCategory.daemonRejected;
  }
  if (code == XelisWalletErrorCode.insufficientFunds) {
    return AppFailureCategory.insufficientFunds;
  }
  if (code == XelisWalletErrorCode.conflict) {
    return AppFailureCategory.conflict;
  }
  if (code == XelisWalletErrorCode.operationInProgress) {
    return AppFailureCategory.operationInProgress;
  }
  if (code == XelisWalletErrorCode.notFound) {
    return AppFailureCategory.notFound;
  }
  if (code == XelisWalletErrorCode.unsupported) {
    return AppFailureCategory.unsupported;
  }
  if (code == XelisWalletErrorCode.storageFailure) {
    return AppFailureCategory.storageFailure;
  }
  if (code == XelisWalletErrorCode.serializationFailure) {
    return AppFailureCategory.serializationFailure;
  }
  if (code == XelisWalletErrorCode.cancelled) {
    return AppFailureCategory.cancelled;
  }
  if (code == XelisWalletErrorCode.initializationFailure) {
    return AppFailureCategory.initializationFailure;
  }
  if (code == XelisWalletErrorCode.internal) {
    return AppFailureCategory.internalFailure;
  }
  if (code == XelisWalletErrorCode.unsupportedPlatform) {
    return AppFailureCategory.unsupportedPlatform;
  }
  if (code == XelisWalletErrorCode.nativePanic) {
    return AppFailureCategory.nativePanic;
  }
  if (code == XelisWalletErrorCode.bridgeFailure) {
    return AppFailureCategory.bridgeFailure;
  }
  if (code == XelisWalletErrorCode.operationFailed) {
    return AppFailureCategory.operationFailure;
  }
  if (code == XelisWalletErrorCode.streamLagged ||
      code == XelisWalletErrorCode.streamClosedUnexpectedly) {
    return AppFailureCategory.operationFailure;
  }
  return AppFailureCategory.unexpected;
}
