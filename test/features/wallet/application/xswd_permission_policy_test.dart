import '../../../helpers/xswd_test_payload.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('non-persistable and unknown accepts are downgraded to ask', () {
    final nonPersistableMethods = WalletMethod.values
        .where((method) => !xswdMethodPolicy(method).canAllowForConnection)
        .toList(growable: false);
    final normalized = normalizeXswdPermissionPolicies({
      for (final method in nonPersistableMethods)
        method.jsonKey: XelisXswdPermissionPolicy.accept,
      WalletMethod.getBalance.jsonKey: XelisXswdPermissionPolicy.accept,
      'future_method': XelisXswdPermissionPolicy.accept,
      'future_rejected_method': XelisXswdPermissionPolicy.reject,
      'track_asset': XelisXswdPermissionPolicy.accept,
      'untrack_asset': XelisXswdPermissionPolicy.reject,
      'subscribe': XelisXswdPermissionPolicy.accept,
      'unsubscribe': XelisXswdPermissionPolicy.reject,
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
    expect(normalized['track_asset'], XelisXswdPermissionPolicy.accept);
    expect(normalized['untrack_asset'], XelisXswdPermissionPolicy.reject);
    expect(normalized['subscribe'], XelisXswdPermissionPolicy.accept);
    expect(normalized['unsubscribe'], XelisXswdPermissionPolicy.reject);
    expect(
      normalized['future_rejected_method'],
      XelisXswdPermissionPolicy.reject,
    );
  });

  test(
    'sign_data cannot become automatic and can be blocked for the connection',
    () {
      final review = XswdPermissionReview.parse(
        xswdTestPermission(method: 'sign_data', params: 'Sign-in challenge'),
      );
      expect(
        normalizeXswdDecision(XelisXswdDecision.alwaysAccept, review),
        XelisXswdDecision.accept,
      );
      expect(
        normalizeXswdDecision(XelisXswdDecision.alwaysReject, review),
        XelisXswdDecision.alwaysReject,
      );
      expect(
        normalizeXswdPermissionPolicies({
          'sign_data': XelisXswdPermissionPolicy.accept,
        }),
        {'sign_data': XelisXswdPermissionPolicy.ask},
      );
    },
  );

  test('transaction alwaysAccept is reduced to a one-time accept', () {
    final review = XswdPermissionReview.parse(
      xswdTestPermission(
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
      normalizeXswdDecision(XelisXswdDecision.alwaysReject, review),
      XelisXswdDecision.alwaysReject,
    );
    expect(
      normalizeXswdDecision(XelisXswdDecision.reject, review),
      XelisXswdDecision.reject,
    );
  });
}
