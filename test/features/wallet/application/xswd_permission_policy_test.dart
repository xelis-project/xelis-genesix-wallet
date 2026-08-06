import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('persisted transaction and signing accepts are downgraded to ask', () {
    final normalized = normalizeXswdPermissionPolicies({
      WalletMethod.buildTransaction.jsonKey: XelisXswdPermissionPolicy.accept,
      WalletMethod.signData.jsonKey: XelisXswdPermissionPolicy.accept,
      WalletMethod.finalizeUnsignedTransaction.jsonKey:
          XelisXswdPermissionPolicy.accept,
      WalletMethod.getBalance.jsonKey: XelisXswdPermissionPolicy.accept,
    });

    expect(
      normalized[WalletMethod.buildTransaction.jsonKey],
      XelisXswdPermissionPolicy.ask,
    );
    expect(
      normalized[WalletMethod.signData.jsonKey],
      XelisXswdPermissionPolicy.ask,
    );
    expect(
      normalized[WalletMethod.finalizeUnsignedTransaction.jsonKey],
      XelisXswdPermissionPolicy.ask,
    );
    expect(
      normalized[WalletMethod.getBalance.jsonKey],
      XelisXswdPermissionPolicy.accept,
    );
  });

  test('transaction alwaysAccept is reduced to a one-time accept', () {
    final review = XswdPermissionReview.parse(
      PermissionRpcRequest(
        id: 1,
        jsonrpc: '2.0',
        method: WalletMethod.buildTransaction.jsonKey,
        params: {
          'burn': {'asset': 'asset-hash', 'amount': 1},
        },
      ),
    );

    expect(
      normalizeXswdDecision(XelisXswdDecision.alwaysAccept, review),
      XelisXswdDecision.accept,
    );
    expect(
      normalizeXswdDecision(XelisXswdDecision.reject, review),
      XelisXswdDecision.reject,
    );
  });
}
