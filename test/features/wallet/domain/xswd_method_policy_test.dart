import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

void main() {
  test('resolves only exact wallet RPC keys', () {
    for (final method in WalletMethod.values) {
      expect(tryResolveXswdWalletMethod(method.jsonKey), method);
      expect(
        tryXswdMethodPolicyForKey(method.jsonKey),
        same(xswdMethodPolicy(method)),
      );
      for (final invalidKey in [
        'wallet.${method.jsonKey}',
        ' ${method.jsonKey}',
        '${method.jsonKey} ',
        method.jsonKey.toUpperCase(),
      ]) {
        expect(tryResolveXswdWalletMethod(invalidKey), isNull);
        expect(tryXswdMethodPolicyForKey(invalidKey), isNull);
      }
    }
    for (final key in ['', 'future_method', 'subscribe', 'unsubscribe']) {
      expect(tryResolveXswdWalletMethod(key), isNull);
    }
  });

  test('classifies every SDK wallet method explicitly', () {
    final expected =
        <
          WalletMethod,
          ({
            XswdApprovalMode approvalMode,
            XswdMethodEffect effect,
            bool canAllowForConnection,
            bool canPrefetch,
          })
        >{
          for (final method in const [
            WalletMethod.getVersion,
            WalletMethod.getNetwork,
            WalletMethod.getTopoheight,
            WalletMethod.splitAddress,
            WalletMethod.getAssetPrecision,
            WalletMethod.isOnline,
            WalletMethod.estimateFees,
            WalletMethod.estimateExtraDataSize,
            WalletMethod.verifySignedData,
            WalletMethod.verifyHumanReadableProof,
          ])
            method: (
              approvalMode: XswdApprovalMode.connection,
              effect: XswdMethodEffect.publicInformation,
              canAllowForConnection: true,
              canPrefetch: true,
            ),
          for (final method in const [
            WalletMethod.networkInfo,
            WalletMethod.getNonce,
            WalletMethod.getAddress,
            WalletMethod.getBalance,
            WalletMethod.hasBalance,
            WalletMethod.getTrackedAssets,
            WalletMethod.getTransaction,
            WalletMethod.listTransactions,
            WalletMethod.getAssets,
            WalletMethod.getAsset,
            WalletMethod.dumpTransaction,
            WalletMethod.getPendingTransactions,
            WalletMethod.isAssetTracked,
            WalletMethod.searchTransaction,
          ])
            method: (
              approvalMode: XswdApprovalMode.connection,
              effect: XswdMethodEffect.walletData,
              canAllowForConnection: true,
              canPrefetch: true,
            ),
          for (final method in [
            WalletMethod.trackAsset,
            WalletMethod.untrackAsset,
          ])
            method: (
              approvalMode: XswdApprovalMode.connection,
              effect: XswdMethodEffect.walletControl,
              canAllowForConnection: true,
              canPrefetch: true,
            ),
          WalletMethod.signData: (
            approvalMode: XswdApprovalMode.individual,
            effect: XswdMethodEffect.signing,
            canAllowForConnection: false,
            canPrefetch: false,
          ),
          WalletMethod.buildTransaction: (
            approvalMode: XswdApprovalMode.individual,
            effect: XswdMethodEffect.transaction,
            canAllowForConnection: false,
            canPrefetch: false,
          ),
          for (final method in const [
            WalletMethod.buildTransactionOffline,
            WalletMethod.buildUnsignedTransaction,
            WalletMethod.finalizeUnsignedTransaction,
          ])
            method: (
              approvalMode: XswdApprovalMode.unavailable,
              effect: XswdMethodEffect.transaction,
              canAllowForConnection: false,
              canPrefetch: false,
            ),
          for (final method in const [WalletMethod.signUnsignedTransaction])
            method: (
              approvalMode: XswdApprovalMode.unavailable,
              effect: XswdMethodEffect.signing,
              canAllowForConnection: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.rescan,
            WalletMethod.clearTxCache,
            WalletMethod.setOnlineMode,
            WalletMethod.setOfflineMode,
          ])
            method: (
              approvalMode: XswdApprovalMode.unavailable,
              effect: XswdMethodEffect.walletControl,
              canAllowForConnection: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.decryptExtraData,
            WalletMethod.decryptCiphertext,
          ])
            method: (
              approvalMode: XswdApprovalMode.unavailable,
              effect: XswdMethodEffect.decryption,
              canAllowForConnection: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.createOwnershipProof,
            WalletMethod.createBalanceProof,
          ])
            method: (
              approvalMode: XswdApprovalMode.unavailable,
              effect: XswdMethodEffect.proof,
              canAllowForConnection: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.getMatchingKeys,
            WalletMethod.countMatchingEntries,
            WalletMethod.getValueFromKey,
            WalletMethod.store,
            WalletMethod.delete,
            WalletMethod.deleteTreeEntries,
            WalletMethod.hasKey,
            WalletMethod.queryDB,
          ])
            method: (
              approvalMode: XswdApprovalMode.connection,
              effect: XswdMethodEffect.appStorage,
              canAllowForConnection: true,
              canPrefetch: true,
            ),
        };

    expect(expected.keys.toSet(), WalletMethod.values.toSet());
    for (final method in WalletMethod.values) {
      final policy = xswdMethodPolicy(method);
      final expectedPolicy = expected[method]!;
      expect(
        policy.reviewKind,
        method == WalletMethod.buildTransaction
            ? XswdReviewKind.transaction
            : method == WalletMethod.signData
            ? XswdReviewKind.dataSignature
            : XswdReviewKind.generic,
      );
      expect(
        policy.approvalMode,
        expectedPolicy.approvalMode,
        reason: method.jsonKey,
      );
      expect(policy.effect, expectedPolicy.effect, reason: method.jsonKey);
      expect(
        policy.canAllowForConnection,
        expectedPolicy.canAllowForConnection,
        reason: method.jsonKey,
      );
      expect(
        policy.canPrefetch,
        expectedPolicy.canPrefetch,
        reason: method.jsonKey,
      );
    }
  });

  test(
    'resolves exact RPC and subscription keys with one policy catalogue',
    () {
      expect(
        tryXswdMethodPolicyForKey(WalletMethod.getBalance.jsonKey),
        same(xswdMethodPolicy(WalletMethod.getBalance)),
      );
      expect(tryXswdMethodPolicyForKey('wallet.get_balance'), isNull);
      expect(tryXswdMethodPolicyForKey('future_method'), isNull);
      expect(xswdMethodCount, WalletMethod.values.length + 2);
      for (final method in ['subscribe', 'unsubscribe']) {
        final policy = tryXswdMethodPolicyForKey(method)!;
        expect(policy.isSupported, isTrue);
        expect(policy.canPrefetch, isTrue);
        expect(policy.canAllowForConnection, isTrue);
        expect(tryXswdMethodPolicyForKey('wallet.$method'), isNull);
      }
    },
  );
}
