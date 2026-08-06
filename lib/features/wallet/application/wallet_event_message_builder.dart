import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

typedef ContactNameLookup = Future<String?> Function(String address);

class WalletEventMessageBuilder {
  const WalletEventMessageBuilder({
    required this.loc,
    required this.knownAssets,
    required this.contactNameForAddress,
  });

  final AppLocalizations loc;
  final Map<String, wallet_flutter.XelisWalletAssetMetadata> knownAssets;
  final ContactNameLookup contactNameForAddress;

  Future<String> incomingTransaction(
    wallet_flutter.XelisWalletIncomingEntry txType,
  ) async {
    if (txType.isMultiTransfer()) {
      return loc.multiple_transfers_detected;
    }

    final transfer = txType.transfers.first;
    final assetText = _assetNameOrHash(transfer.asset);
    final amountText = _formatAmountOrAtomic(
      amount: transfer.amount,
      assetHash: transfer.asset,
    );
    final contactName = await contactNameForAddress(txType.from);
    final fromText = contactName?.isNotEmpty == true
        ? contactName!
        : truncateText(txType.from);

    return '${loc.asset}: $assetText\n${loc.amount}: +$amountText\n${loc.from}: $fromText';
  }

  String burnTransaction(wallet_flutter.XelisWalletBurnEntry txType) {
    final assetText = _assetNameOrHash(txType.asset);
    final amountText = _formatAmountOrAtomic(
      amount: txType.amount,
      assetHash: txType.asset,
    );

    return '${loc.asset}: $assetText\n${loc.amount}: -$amountText';
  }

  String _assetNameOrHash(String assetHash) {
    return knownAssets[assetHash]?.name ?? truncateText(assetHash);
  }

  String _formatAmountOrAtomic({
    required BigInt amount,
    required String assetHash,
  }) {
    final asset = knownAssets[assetHash];
    if (asset == null) {
      return amount.toString();
    }
    return formatCoin(amount, asset.decimals, asset.ticker);
  }
}

extension WalletEventTransactionUtils
    on wallet_flutter.XelisWalletTransactionEntryData {
  bool isMultiTransfer() {
    return switch (this) {
      wallet_flutter.XelisWalletIncomingEntry(:final transfers) =>
        transfers.length > 1,
      wallet_flutter.XelisWalletOutgoingEntry(:final transfers) =>
        transfers.length > 1,
      _ => false,
    };
  }
}
