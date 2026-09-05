import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

typedef AssetMetadataLookup =
    Future<wallet_flutter.XelisWalletAssetMetadata> Function(String assetHash);
typedef AssetKnownCheck = bool Function(String assetHash);
typedef ActiveRepositoryCheck = bool Function();
typedef AssetMetadataFetchErrorHandler = void Function(
  String assetHash,
  Object error,
);

class WalletTransactionAssetResolver {
  const WalletTransactionAssetResolver({
    required this.getAssetMetadata,
    required this.hasKnownAsset,
    required this.isActiveRepository,
    required this.onFetchError,
  });

  final AssetMetadataLookup getAssetMetadata;
  final AssetKnownCheck hasKnownAsset;
  final ActiveRepositoryCheck isActiveRepository;
  final AssetMetadataFetchErrorHandler onFetchError;

  Future<Map<String, wallet_flutter.XelisWalletAssetMetadata>?>
  fetchMissingAssets(
    wallet_flutter.XelisWalletTransactionEntryData txType,
  ) async {
    final assetHashes = assetHashesFromTransaction(txType);
    if (assetHashes.isEmpty) {
      return const <String, wallet_flutter.XelisWalletAssetMetadata>{};
    }

    final missingAssets = assetHashes
        .where((assetHash) => !hasKnownAsset(assetHash))
        .toSet();
    if (missingAssets.isEmpty) {
      return const <String, wallet_flutter.XelisWalletAssetMetadata>{};
    }

    final fetchedAssets = <String, wallet_flutter.XelisWalletAssetMetadata>{};
    for (final assetHash in missingAssets) {
      if (hasKnownAsset(assetHash)) {
        continue;
      }

      try {
        final assetData = await getAssetMetadata(assetHash);
        if (!isActiveRepository()) {
          return null;
        }
        fetchedAssets[assetHash] = assetData;
      } catch (error) {
        if (!isActiveRepository()) {
          return null;
        }
        onFetchError(assetHash, error);
      }
    }

    return fetchedAssets;
  }
}

Set<String> assetHashesFromTransaction(
  wallet_flutter.XelisWalletTransactionEntryData txType,
) {
  return switch (txType) {
    wallet_flutter.XelisWalletIncomingEntry() =>
      txType.transfers.map((transfer) => transfer.asset).toSet(),
    wallet_flutter.XelisWalletOutgoingEntry() =>
      txType.transfers.map((transfer) => transfer.asset).toSet(),
    wallet_flutter.XelisWalletBurnEntry() => {txType.asset},
    wallet_flutter.XelisWalletInvokeContractEntry() => {
      ...txType.deposits.map((deposit) => deposit.asset),
      ...txType.received.expand(
        (group) => group.transfers.map((transfer) => transfer.asset),
      ),
    },
    wallet_flutter.XelisWalletDeployContractEntry(invoke: final invoke) => {
      if (invoke != null) ...invoke.deposits.map((deposit) => deposit.asset),
    },
    wallet_flutter.XelisWalletIncomingContractEntry() =>
      txType.transfers
          .expand((group) => group.transfers.map((transfer) => transfer.asset))
          .toSet(),
    wallet_flutter.XelisWalletCoinbaseEntry() ||
    wallet_flutter.XelisWalletMultisigEntry() ||
    wallet_flutter.XelisWalletIncomingBlobEntry() ||
    wallet_flutter.XelisWalletOutgoingBlobEntry() => const <String>{},
  };
}
