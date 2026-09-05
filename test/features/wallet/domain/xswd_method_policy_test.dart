import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

void main() {
  test('classifies every SDK wallet method explicitly', () {
    final expected =
        <
          WalletMethod,
          ({
            XswdMethodSupport support,
            XswdMethodEffect effect,
            bool canPersist,
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
              support: XswdMethodSupport.standardReview,
              effect: XswdMethodEffect.publicInformation,
              canPersist: true,
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
              support: XswdMethodSupport.standardReview,
              effect: XswdMethodEffect.walletData,
              canPersist: true,
              canPrefetch: true,
            ),
          WalletMethod.buildTransaction: (
            support: XswdMethodSupport.dedicatedTransactionReview,
            effect: XswdMethodEffect.transaction,
            canPersist: false,
            canPrefetch: false,
          ),
          for (final method in const [
            WalletMethod.buildTransactionOffline,
            WalletMethod.buildUnsignedTransaction,
            WalletMethod.finalizeUnsignedTransaction,
          ])
            method: (
              support: XswdMethodSupport.unsupported,
              effect: XswdMethodEffect.transaction,
              canPersist: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.signUnsignedTransaction,
            WalletMethod.signData,
          ])
            method: (
              support: XswdMethodSupport.unsupported,
              effect: XswdMethodEffect.signing,
              canPersist: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.rescan,
            WalletMethod.clearTxCache,
            WalletMethod.setOnlineMode,
            WalletMethod.setOfflineMode,
            WalletMethod.trackAsset,
            WalletMethod.untrackAsset,
          ])
            method: (
              support: XswdMethodSupport.unsupported,
              effect: XswdMethodEffect.walletControl,
              canPersist: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.decryptExtraData,
            WalletMethod.decryptCiphertext,
          ])
            method: (
              support: XswdMethodSupport.unsupported,
              effect: XswdMethodEffect.decryption,
              canPersist: false,
              canPrefetch: false,
            ),
          for (final method in const [
            WalletMethod.createOwnershipProof,
            WalletMethod.createBalanceProof,
          ])
            method: (
              support: XswdMethodSupport.unsupported,
              effect: XswdMethodEffect.proof,
              canPersist: false,
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
              support: XswdMethodSupport.standardReview,
              effect: XswdMethodEffect.appStorage,
              canPersist: true,
              canPrefetch: true,
            ),
        };

    expect(expected.keys.toSet(), WalletMethod.values.toSet());
    for (final method in WalletMethod.values) {
      final policy = xswdMethodPolicy(method);
      final expectedPolicy = expected[method]!;
      expect(policy.support, expectedPolicy.support, reason: method.jsonKey);
      expect(policy.effect, expectedPolicy.effect, reason: method.jsonKey);
      expect(
        policy.canPersist,
        expectedPolicy.canPersist,
        reason: method.jsonKey,
      );
      expect(
        policy.canPrefetch,
        expectedPolicy.canPrefetch,
        reason: method.jsonKey,
      );
    }
  });

  test('resolves only exact unprefixed SDK method keys', () {
    expect(
      tryXswdMethodPolicyForKey(WalletMethod.getBalance.jsonKey),
      same(xswdMethodPolicy(WalletMethod.getBalance)),
    );
    expect(tryXswdMethodPolicyForKey('wallet.get_balance'), isNull);
    expect(tryXswdMethodPolicyForKey('future_method'), isNull);
  });
}
