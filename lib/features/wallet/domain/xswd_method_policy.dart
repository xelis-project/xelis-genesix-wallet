import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

/// How Genesix can review one wallet method requested through XSWD.
enum XswdMethodSupport {
  /// The generic permission review is sufficient for this method.
  standardReview,

  /// The method has a dedicated, request-bound review.
  dedicatedTransactionReview,

  /// Genesix cannot currently review this method safely.
  unsupported,
}

/// The user-visible effect category of an XSWD wallet method.
enum XswdMethodEffect {
  publicInformation,
  walletData,
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
    required this.support,
    required this.effect,
    required this.canPersist,
    required this.canPrefetch,
  });

  final XswdMethodSupport support;
  final XswdMethodEffect effect;
  final bool canPersist;
  final bool canPrefetch;

  bool get isSupported => support != XswdMethodSupport.unsupported;
}

const _publicInformationPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.standardReview,
  effect: XswdMethodEffect.publicInformation,
  canPersist: true,
  canPrefetch: true,
);

const _walletDataPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.standardReview,
  effect: XswdMethodEffect.walletData,
  canPersist: true,
  canPrefetch: true,
);

const _transactionReviewPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.dedicatedTransactionReview,
  effect: XswdMethodEffect.transaction,
  canPersist: false,
  canPrefetch: false,
);

const _unsupportedTransactionPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.unsupported,
  effect: XswdMethodEffect.transaction,
  canPersist: false,
  canPrefetch: false,
);

const _unsupportedWalletControlPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.unsupported,
  effect: XswdMethodEffect.walletControl,
  canPersist: false,
  canPrefetch: false,
);

const _unsupportedDecryptionPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.unsupported,
  effect: XswdMethodEffect.decryption,
  canPersist: false,
  canPrefetch: false,
);

const _unsupportedSigningPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.unsupported,
  effect: XswdMethodEffect.signing,
  canPersist: false,
  canPrefetch: false,
);

const _unsupportedProofPolicy = XswdMethodPolicy(
  support: XswdMethodSupport.unsupported,
  effect: XswdMethodEffect.proof,
  canPersist: false,
  canPrefetch: false,
);

const _appStoragePolicy = XswdMethodPolicy(
  support: XswdMethodSupport.standardReview,
  effect: XswdMethodEffect.appStorage,
  canPersist: true,
  canPrefetch: true,
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
  WalletMethod.signUnsignedTransaction ||
  WalletMethod.signData => _unsupportedSigningPolicy,
  WalletMethod.rescan ||
  WalletMethod.clearTxCache ||
  WalletMethod.setOnlineMode ||
  WalletMethod.setOfflineMode ||
  WalletMethod.trackAsset ||
  WalletMethod.untrackAsset => _unsupportedWalletControlPolicy,
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
  return method == null ? null : xswdMethodPolicy(method);
}
