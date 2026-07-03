import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

typedef ContactNameLookup = Future<String?> Function(String address);

class WalletEventMessageBuilder {
  const WalletEventMessageBuilder({
    required this.loc,
    required this.knownAssets,
    required this.contactNameForAddress,
  });

  final AppLocalizations loc;
  final Map<String, sdk.AssetData> knownAssets;
  final ContactNameLookup contactNameForAddress;

  Future<String> incomingTransaction(sdk.IncomingEntry txType) async {
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

  String burnTransaction(sdk.BurnEntry txType) {
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
    required int amount,
    required String assetHash,
  }) {
    final asset = knownAssets[assetHash];
    if (asset == null) {
      return amount.toString();
    }
    return formatCoin(amount, asset.decimals, asset.ticker);
  }
}

extension WalletEventTransactionUtils on sdk.TransactionEntryType {
  bool isMultiTransfer() {
    return switch (this) {
      sdk.IncomingEntry(:final transfers) => transfers.length > 1,
      sdk.OutgoingEntry(:final transfers) => transfers.length > 1,
      _ => false,
    };
  }
}
