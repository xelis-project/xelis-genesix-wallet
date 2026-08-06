import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

enum TransferDirection { incoming, outgoing }

class TransferEntryRow {
  final TransferDirection dir;
  final String amountText; // already formatted with sign
  final String? destination; // for outgoing transfers, null for incoming
  final XelisWalletExtraData? extra;
  final String asset;
  final bool destinationIsExactMatch;

  TransferEntryRow({
    required this.dir,
    required this.amountText,
    required this.asset,
    this.destination,
    this.extra,
    this.destinationIsExactMatch = false,
  });
}

List<TransferEntryRow> entryRowFromIncoming(
  XelisWalletIncomingEntry incoming,
  Map<String, XelisWalletAssetMetadata> knownAssets,
  bool hideZeroTransfer,
) {
  return incoming.transfers
      .skipWhile(
        (transfer) => hideZeroTransfer && transfer.amount == BigInt.zero,
      )
      .map((transfer) {
        final formattedData = getFormattedAssetNameAndAmount(
          knownAssets,
          transfer.asset,
          transfer.amount,
        );
        final assetName = formattedData.$1;
        final amount = '+${formattedData.$2}';

        return TransferEntryRow(
          dir: TransferDirection.incoming,
          amountText: amount,
          asset: assetName,
          extra: transfer.extraData,
        );
      })
      .toList();
}

List<TransferEntryRow> entryRowFromOutgoing(
  XelisWalletOutgoingEntry outgoing,
  Map<String, XelisWalletAssetMetadata> knownAssets,
  bool hideZeroTransfer, {
  List<XelisAddressBookEntry?> exactDestinations = const [],
}) {
  return outgoing.transfers.indexed
      .skipWhile((item) => hideZeroTransfer && item.$2.amount == BigInt.zero)
      .map((item) {
        final index = item.$1;
        final transfer = item.$2;
        final formattedData = getFormattedAssetNameAndAmount(
          knownAssets,
          transfer.asset,
          transfer.amount,
        );
        final assetName = formattedData.$1;
        final amount = '-${formattedData.$2}';
        final exactDestination = index < exactDestinations.length
            ? exactDestinations[index]
            : null;

        return TransferEntryRow(
          dir: TransferDirection.outgoing,
          destination:
              exactDestination?.destination.address ?? transfer.destination,
          destinationIsExactMatch: exactDestination != null,
          amountText: amount,
          asset: assetName,
          extra: transfer.extraData,
        );
      })
      .toList();
}
