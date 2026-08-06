import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('application failures contain only reviewed safe identifiers', () {
    final failure = AppFailure.application(
      operation: 'wallet.path.resolve',
      code: 'wallet_name_invalid',
      exceptionType: 'InvalidWalletNameException',
      category: AppFailureCategory.invalidInput,
    );

    expect(failure.contractVersion, AppFailureContract.currentVersion);
    expect(failure.originContractVersion, isNull);
    expect(failure.source, 'genesix');
    expect(failure.operation, 'wallet.path.resolve');
    expect(failure.code, 'wallet_name_invalid');
    expect(failure.exceptionType, 'InvalidWalletNameException');
    expect(failure.category, AppFailureCategory.invalidInput);
    expect(failure.supportId, matches(RegExp(r'^GNX(?:-[0-9A-F]{4}){5}$')));
    expect(failure.nativeKind, isNull);
    expect(failure.nativeCode, isNull);
  });

  group('AppFailure.fromXelis', () {
    test('copies only support-safe fields and preserves the support id', () {
      const diagnostic =
          r'walletPath=C:\private\wallet amount=42 privileged-detail';
      final failure = AppFailure.fromXelis(
        _xelisException(
          XelisWalletErrorCode.networkFailure,
          diagnosticMessage: diagnostic,
          nativeKind: 'JSON_RPC_ERROR',
          nativeCode: -32603,
        ),
      );

      expect(failure.contractVersion, AppFailureContract.currentVersion);
      expect(
        failure.originContractVersion,
        XelisWalletErrorContract.currentVersion,
      );
      expect(failure.exceptionType, 'XelisWalletOperationException');
      expect(failure.source, XelisWalletErrorSource.xelisCommon.name);
      expect(
        failure.operation,
        XelisWalletOperation.configurationInitialize.id,
      );
      expect(failure.code, XelisWalletErrorCode.networkFailure.id);
      expect(failure.supportId, _supportId);
      expect(failure.nativeKind, 'JSON_RPC_ERROR');
      expect(failure.nativeCode, -32603);
      expect(failure.category, AppFailureCategory.networkFailure);
      expect(failure.supportReference, contains(_supportId));
      expect(failure.supportReference, startsWith(_supportId));
      expect(failure.supportReference, isNot(contains(diagnostic)));
      expect(failure.toString(), isNot(contains(diagnostic)));
    });

    final categoryCases = <(XelisWalletErrorCode, AppFailureCategory)>[
      (XelisWalletErrorCode.invalidInput, AppFailureCategory.invalidInput),
      (
        XelisWalletErrorCode.authenticationOrCorruptData,
        AppFailureCategory.authenticationOrCorruptData,
      ),
      (XelisWalletErrorCode.offline, AppFailureCategory.offline),
      (XelisWalletErrorCode.networkFailure, AppFailureCategory.networkFailure),
      (
        XelisWalletErrorCode.networkMismatch,
        AppFailureCategory.networkMismatch,
      ),
      (XelisWalletErrorCode.daemonRejected, AppFailureCategory.daemonRejected),
      (
        XelisWalletErrorCode.insufficientFunds,
        AppFailureCategory.insufficientFunds,
      ),
      (XelisWalletErrorCode.conflict, AppFailureCategory.conflict),
      (
        XelisWalletErrorCode.operationInProgress,
        AppFailureCategory.operationInProgress,
      ),
      (XelisWalletErrorCode.notFound, AppFailureCategory.notFound),
      (XelisWalletErrorCode.unsupported, AppFailureCategory.unsupported),
      (XelisWalletErrorCode.storageFailure, AppFailureCategory.storageFailure),
      (
        XelisWalletErrorCode.serializationFailure,
        AppFailureCategory.serializationFailure,
      ),
      (XelisWalletErrorCode.cancelled, AppFailureCategory.cancelled),
      (
        XelisWalletErrorCode.initializationFailure,
        AppFailureCategory.initializationFailure,
      ),
      (XelisWalletErrorCode.internal, AppFailureCategory.internalFailure),
      (
        XelisWalletErrorCode.unsupportedPlatform,
        AppFailureCategory.unsupportedPlatform,
      ),
      (XelisWalletErrorCode.nativePanic, AppFailureCategory.nativePanic),
      (XelisWalletErrorCode.bridgeFailure, AppFailureCategory.bridgeFailure),
      (
        XelisWalletErrorCode.operationFailed,
        AppFailureCategory.operationFailure,
      ),
      (XelisWalletErrorCode.streamLagged, AppFailureCategory.operationFailure),
      (
        XelisWalletErrorCode.streamClosedUnexpectedly,
        AppFailureCategory.operationFailure,
      ),
    ];

    for (final (code, expectedCategory) in categoryCases) {
      test('maps ${code.id} to $expectedCategory', () {
        final failure = AppFailure.fromXelis(_xelisException(code));

        expect(failure.category, expectedCategory);
        expect(failure.code, code.id);
      });
    }
  });
}

const _supportId = 'XWF-1234-ABCD-5678-EF90-1234';

XelisWalletOperationException _xelisException(
  XelisWalletErrorCode code, {
  String? diagnosticMessage,
  String? nativeKind,
  int? nativeCode,
}) {
  return XelisWalletOperationException(
    source: XelisWalletErrorSource.xelisCommon,
    operation: XelisWalletOperation.configurationInitialize,
    code: code,
    supportId: _supportId,
    diagnosticMessage: diagnosticMessage,
    nativeKind: nativeKind,
    nativeCode: nativeCode,
  );
}
