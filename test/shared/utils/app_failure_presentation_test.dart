import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/shared/utils/app_failure_presentation.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  final localizations = AppLocalizationsEn();

  test('uses localized messages for actionable wallet categories', () {
    expect(
      appFailureDescription(
        localizations,
        _failure(XelisWalletErrorCode.authenticationOrCorruptData),
      ),
      localizations.wallet_failure_authentication_or_corrupt_data,
    );
    expect(
      appFailureDescription(
        localizations,
        _failure(XelisWalletErrorCode.networkMismatch),
      ),
      localizations.network_mismatch,
    );
    expect(
      appFailureDescription(
        localizations,
        _failure(XelisWalletErrorCode.insufficientFunds),
      ),
      localizations.wallet_failure_insufficient_funds,
    );
  });

  test('uses generic localized copy for technical failures', () {
    expect(
      appFailureDescription(
        localizations,
        _failure(XelisWalletErrorCode.internal),
      ),
      localizations.wallet_failure_generic,
    );
  });

  test('keeps a complete support-safe raw reference', () {
    final failure = _failure(XelisWalletErrorCode.networkFailure);

    expect(failure.supportReference, contains(failure.source));
    expect(failure.supportReference, contains(failure.operation));
    expect(failure.supportReference, contains(failure.code));
    expect(failure.supportReference, contains(failure.supportId));
  });
}

AppFailure _failure(XelisWalletErrorCode code) {
  return AppFailure.fromXelis(
    XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.configurationInitialize,
      code: code,
      supportId: 'XWF-1234-ABCD-5678-EF90-1234',
      diagnosticMessage: 'must never reach presentation',
    ),
  );
}
