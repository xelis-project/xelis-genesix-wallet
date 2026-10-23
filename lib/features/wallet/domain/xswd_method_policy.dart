import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

/// Presentation used when asking for one XSWD permission.
enum XswdReviewKind { generic, transaction, dataSignature }

/// Whether approval can cover subsequent calls on the same live connection.
enum XswdApprovalMode { connection, individual, unavailable }

/// The user-visible effect category of an XSWD wallet method.
enum XswdMethodEffect {
  publicInformation,
  walletData,
  walletSubscription,
  walletUnsubscription,
  transaction,
  walletControl,
  decryption,
  signing,
  proof,
  appStorage,
}

/// Genesix's exhaustive policy for one SDK-owned wallet method.
final class XswdMethodPolicy {
  const XswdMethodPolicy({
    this.reviewKind = XswdReviewKind.generic,
    required this.approvalMode,
    required this.effect,
  });

  final XswdReviewKind reviewKind;
  final XswdApprovalMode approvalMode;
  final XswdMethodEffect effect;
  bool get isSupported => approvalMode != XswdApprovalMode.unavailable;
  bool get canAllowForConnection => approvalMode == XswdApprovalMode.connection;
  bool get canPrefetch => canAllowForConnection;
}

const _publicInformationPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.connection,
  effect: XswdMethodEffect.publicInformation,
);

const _walletDataPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.connection,
  effect: XswdMethodEffect.walletData,
);

const _transactionReviewPolicy = XswdMethodPolicy(
  reviewKind: XswdReviewKind.transaction,
  approvalMode: XswdApprovalMode.individual,
  effect: XswdMethodEffect.transaction,
);

XswdMethodPolicy _subscriptionPolicy(XelisSubscription method) =>
    switch (method) {
      XelisSubscription.subscribe => const XswdMethodPolicy(
        approvalMode: XswdApprovalMode.connection,
        effect: XswdMethodEffect.walletSubscription,
      ),
      XelisSubscription.unsubscribe => const XswdMethodPolicy(
        approvalMode: XswdApprovalMode.connection,
        effect: XswdMethodEffect.walletUnsubscription,
      ),
    };

int get xswdMethodCount =>
    WalletMethod.values.length + XelisSubscription.values.length;

const _unsupportedTransactionPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.unavailable,
  effect: XswdMethodEffect.transaction,
);

const _unsupportedWalletControlPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.unavailable,
  effect: XswdMethodEffect.walletControl,
);

const _unsupportedDecryptionPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.unavailable,
  effect: XswdMethodEffect.decryption,
);

const _dataSignaturePolicy = XswdMethodPolicy(
  reviewKind: XswdReviewKind.dataSignature,
  approvalMode: XswdApprovalMode.individual,
  effect: XswdMethodEffect.signing,
);

const _unsupportedSigningPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.unavailable,
  effect: XswdMethodEffect.signing,
);

const _unsupportedProofPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.unavailable,
  effect: XswdMethodEffect.proof,
);

const _assetTrackingPolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.connection,
  effect: XswdMethodEffect.walletControl,
);

const _appStoragePolicy = XswdMethodPolicy(
  approvalMode: XswdApprovalMode.connection,
  effect: XswdMethodEffect.appStorage,
);

/// Returns the explicitly authored Genesix policy for every SDK wallet method.
///
/// This switch deliberately has no fallback. Adding a [WalletMethod] in the SDK
/// must make this policy fail analysis until the new capability is classified.
XswdMethodPolicy xswdMethodPolicy(WalletMethod method) => switch (method) {
  WalletMethod.getVersion ||
  WalletMethod.getNetwork ||
  WalletMethod.getTopoheight ||
  WalletMethod.splitAddress ||
  WalletMethod.getAssetPrecision ||
  WalletMethod.isOnline ||
  WalletMethod.estimateFees ||
  WalletMethod.estimateExtraDataSize ||
  WalletMethod.verifySignedData ||
  WalletMethod.verifyHumanReadableProof => _publicInformationPolicy,
  WalletMethod.networkInfo ||
  WalletMethod.getNonce ||
  WalletMethod.getAddress ||
  WalletMethod.getBalance ||
  WalletMethod.hasBalance ||
  WalletMethod.getTrackedAssets ||
  WalletMethod.getTransaction ||
  WalletMethod.listTransactions ||
  WalletMethod.getAssets ||
  WalletMethod.getAsset ||
  WalletMethod.dumpTransaction ||
  WalletMethod.getPendingTransactions ||
  WalletMethod.isAssetTracked ||
  WalletMethod.searchTransaction => _walletDataPolicy,
  WalletMethod.buildTransaction => _transactionReviewPolicy,
  WalletMethod.buildTransactionOffline ||
  WalletMethod.buildUnsignedTransaction ||
  WalletMethod.finalizeUnsignedTransaction => _unsupportedTransactionPolicy,
  WalletMethod.signUnsignedTransaction => _unsupportedSigningPolicy,
  WalletMethod.signData => _dataSignaturePolicy,
  WalletMethod.rescan ||
  WalletMethod.clearTxCache ||
  WalletMethod.setOnlineMode ||
  WalletMethod.setOfflineMode => _unsupportedWalletControlPolicy,
  WalletMethod.trackAsset || WalletMethod.untrackAsset => _assetTrackingPolicy,
  WalletMethod.decryptExtraData ||
  WalletMethod.decryptCiphertext => _unsupportedDecryptionPolicy,
  WalletMethod.createOwnershipProof ||
  WalletMethod.createBalanceProof => _unsupportedProofPolicy,
  WalletMethod.getMatchingKeys ||
  WalletMethod.countMatchingEntries ||
  WalletMethod.getValueFromKey ||
  WalletMethod.store ||
  WalletMethod.delete ||
  WalletMethod.deleteTreeEntries ||
  WalletMethod.hasKey ||
  WalletMethod.queryDB => _appStoragePolicy,
};

WalletMethod? tryResolveXswdWalletMethod(String jsonKey) {
  for (final method in WalletMethod.values) {
    if (method.jsonKey == jsonKey) return method;
  }
  return null;
}

XswdMethodPolicy? tryXswdMethodPolicyForKey(String jsonKey) {
  final method = tryResolveXswdWalletMethod(jsonKey);
  if (method != null) return xswdMethodPolicy(method);
  for (final subscription in XelisSubscription.values) {
    if (subscription.jsonKey == jsonKey) {
      return _subscriptionPolicy(subscription);
    }
  }
  return null;
}
