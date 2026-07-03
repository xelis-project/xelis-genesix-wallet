import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

typedef AssetMetadataLookup = Future<sdk.AssetData> Function(String assetHash);
typedef AssetKnownCheck = bool Function(String assetHash);
typedef ActiveRepositoryCheck = bool Function();
typedef AssetMetadataFetchErrorHandler =
    void Function(String assetHash, Object error);

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

  Future<Map<String, sdk.AssetData>?> fetchMissingAssets(
    sdk.TransactionEntryType txType,
  ) async {
    final assetHashes = assetHashesFromTransaction(txType);
    if (assetHashes.isEmpty) {
      return const <String, sdk.AssetData>{};
    }

    final missingAssets = assetHashes
        .where((assetHash) => !hasKnownAsset(assetHash))
        .toSet();
    if (missingAssets.isEmpty) {
      return const <String, sdk.AssetData>{};
    }

    final fetchedAssets = <String, sdk.AssetData>{};
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

Set<String> assetHashesFromTransaction(sdk.TransactionEntryType txType) {
  return switch (txType) {
    sdk.IncomingEntry() =>
      txType.transfers.map((transfer) => transfer.asset).toSet(),
    sdk.OutgoingEntry() =>
      txType.transfers.map((transfer) => transfer.asset).toSet(),
    sdk.BurnEntry() => {txType.asset},
    sdk.InvokeContractEntry() => {
      ...txType.deposits.keys,
      ...txType.received.keys,
    },
    sdk.DeployContractEntry(invoke: final invoke) => {
      if (invoke != null) ...invoke.deposits.keys,
    },
    sdk.IncomingContractEntry() => txType.transfers.keys.toSet(),
    sdk.CoinbaseEntry() ||
    sdk.MultisigEntry() ||
    sdk.BlobEntry() => const <String>{},
  };
}
