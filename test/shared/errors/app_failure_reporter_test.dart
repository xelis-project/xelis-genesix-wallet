import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('preserves native support metadata without retaining diagnostics', () {
    const diagnostic = 'seed fragment that must not be retained';
    const supportId = 'XWF-1234-ABCD-5678-EF90-1234';
    final error = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.configurationInitialize,
      code: XelisWalletErrorCode.authenticationOrCorruptData,
      supportId: supportId,
      diagnosticMessage: diagnostic,
    );

    final failure = recordAppFailure(
      error,
      StackTrace.empty,
      operation: 'ignored.for.native.failure',
      applicationCode: 'ignored_for_native_failure',
    );

    expect(failure.supportId, supportId);
    expect(failure.contractVersion, AppFailureContract.currentVersion);
    expect(
      failure.originContractVersion,
      XelisWalletErrorContract.currentVersion,
    );
    expect(failure.operation, error.operation.id);
    expect(failure.code, error.code.id);
    expect(failure.toString(), isNot(contains(diagnostic)));
    expect(failure.supportReference, isNot(contains(diagnostic)));
  });

  test('creates a Genesix reference for an unrelated Dart error', () {
    final failure = recordAppFailure(
      const FormatException('untrusted detail'),
      StackTrace.empty,
      operation: 'wallet.import.copy',
      applicationCode: 'wallet_import_copy_failed',
      applicationCategory: AppFailureCategory.storageFailure,
    );

    expect(failure.source, 'genesix');
    expect(failure.originContractVersion, isNull);
    expect(failure.operation, 'wallet.import.copy');
    expect(failure.code, 'wallet_import_copy_failed');
    expect(failure.exceptionType, 'FormatException');
    expect(failure.category, AppFailureCategory.storageFailure);
    expect(failure.supportId, startsWith('GNX-'));
    expect(failure.toString(), isNot(contains('untrusted detail')));
  });

  test('maps a silent background failure without changing native metadata', () {
    const error = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisCommon,
      operation: XelisWalletOperation.walletNetworkConnect,
      code: XelisWalletErrorCode.networkFailure,
      supportId: 'XWF-AAAA-BBBB-CCCC-DDDD-EEEE',
      nativeKind: 'CONNECTION_ERROR',
      diagnosticMessage: 'private endpoint context',
    );

    final failure = appFailureFromError(
      error,
      operation: 'ignored.for.native.failure',
      applicationCode: 'ignored_for_native_failure',
    );

    expect(failure.supportId, error.supportId);
    expect(failure.operation, error.operation.id);
    expect(failure.code, error.code.id);
    expect(failure.category, AppFailureCategory.networkFailure);
    expect(failure.toString(), isNot(contains('private endpoint')));
  });
}
