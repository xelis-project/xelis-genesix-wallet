import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  AppFailure xelisFailure(XelisWalletErrorCode code) {
    return AppFailure.fromXelis(
      XelisWalletOperationException(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.walletNetworkConnect,
        code: code,
        supportId: 'XWF-1111-2222-3333-4444-5555',
      ),
    );
  }

  test('retries only disconnects and typed transport failures', () {
    expect(isRetryableWalletConnectionFailure(null), isTrue);
    expect(
      isRetryableWalletConnectionFailure(
        xelisFailure(XelisWalletErrorCode.networkFailure),
      ),
      isTrue,
    );
    expect(
      isRetryableWalletConnectionFailure(
        xelisFailure(XelisWalletErrorCode.operationInProgress),
      ),
      isTrue,
    );

    for (final code in [
      XelisWalletErrorCode.networkMismatch,
      XelisWalletErrorCode.daemonRejected,
      XelisWalletErrorCode.invalidInput,
      XelisWalletErrorCode.conflict,
      XelisWalletErrorCode.internal,
      XelisWalletErrorCode.bridgeFailure,
    ]) {
      expect(
        isRetryableWalletConnectionFailure(xelisFailure(code)),
        isFalse,
        reason: code.id,
      );
    }

    expect(
      isRetryableWalletConnectionFailure(
        AppFailure.application(
          operation: 'wallet.network.connect',
          code: 'wallet_network_connect_failed',
          exceptionType: 'StateError',
        ),
      ),
      isFalse,
    );
  });
}
