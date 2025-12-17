import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

enum TransferDirection { incoming, outgoing }

class TransferEntryRow {
  final TransferDirection dir;
  final String amountText; // already formatted with sign
  final String? destination; // for outgoing transfers, null for incoming
  final ExtraData? extra;
  final String asset;

  TransferEntryRow({
    required this.dir,
    required this.amountText,
    required this.asset,
    this.destination,
    this.extra,
  });
}

List<TransferEntryRow> entryRowFromIncoming(
  IncomingEntry incoming,
  Map<String, AssetData> knownAssets,
  bool hideZeroTransfer,
) {
  return incoming.transfers
      .skipWhile((transfer) => hideZeroTransfer && transfer.amount == 0)
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
  OutgoingEntry outgoing,
  Map<String, AssetData> knownAssets,
  bool hideZeroTransfer,
) {
  return outgoing.transfers
      .skipWhile((transfer) => hideZeroTransfer && transfer.amount == 0)
      .map((transfer) {
        final formattedData = getFormattedAssetNameAndAmount(
          knownAssets,
          transfer.asset,
          transfer.amount,
        );
        final assetName = formattedData.$1;
        final amount = '-${formattedData.$2}';

        return TransferEntryRow(
          dir: TransferDirection.outgoing,
          destination: transfer.destination,
          amountText: amount,
          asset: assetName,
          extra: transfer.extraData,
        );
      })
      .toList();
}
