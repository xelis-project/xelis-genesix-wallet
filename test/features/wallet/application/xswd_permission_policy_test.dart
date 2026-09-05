import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('non-persistable and unknown accepts are downgraded to ask', () {
    final nonPersistableMethods = WalletMethod.values
        .where((method) => !xswdMethodPolicy(method).canPersist)
        .toList(growable: false);
    final normalized = normalizeXswdPermissionPolicies({
      for (final method in nonPersistableMethods)
        method.jsonKey: XelisXswdPermissionPolicy.accept,
      WalletMethod.getBalance.jsonKey: XelisXswdPermissionPolicy.accept,
      'future_method': XelisXswdPermissionPolicy.accept,
      'future_rejected_method': XelisXswdPermissionPolicy.reject,
    });

    for (final method in nonPersistableMethods) {
      expect(
        normalized[method.jsonKey],
        XelisXswdPermissionPolicy.ask,
        reason: method.jsonKey,
      );
    }
    expect(
      normalized[WalletMethod.getBalance.jsonKey],
      XelisXswdPermissionPolicy.accept,
    );
    expect(normalized['future_method'], XelisXswdPermissionPolicy.ask);
    expect(
      normalized['future_rejected_method'],
      XelisXswdPermissionPolicy.reject,
    );
  });

  test('transaction alwaysAccept is reduced to a one-time accept', () {
    final review = XswdPermissionReview.parse(
      PermissionRpcRequest(
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
