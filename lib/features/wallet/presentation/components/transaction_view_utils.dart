import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

Map<DateTime, List<wallet_flutter.XelisWalletTransactionEntry>>
groupTransactionsByDateSorted2Levels(
  List<wallet_flutter.XelisWalletTransactionEntry> transactions, {
  bool useUtc = false,
  bool assumeInputAlreadyDescByTime = false,
}) {
  final Map<DateTime, List<wallet_flutter.XelisWalletTransactionEntry>>
  grouped = {};

  DateTime dateOnly(DateTime dt) {
    // Avoid using toLocal() if already in local time; normalize to Y/M/D
    final d = useUtc ? dt.toUtc() : dt;
    return DateTime(d.year, d.month, d.day);
  }

  // Group transactions by date
  for (final tx in transactions) {
    final ts = walletTimestampToDateTime(tx.timestampMillis);

    final key = dateOnly(ts);
    final list = grouped.putIfAbsent(
      key,
      () => <wallet_flutter.XelisWalletTransactionEntry>[],
    );
    list.add(tx);
  }

  // If the input is already sorted by timestamp in descending order,
  // we can skip the sorting step.
  if (!assumeInputAlreadyDescByTime) {
    for (final list in grouped.values) {
      list.sort((a, b) {
        final cmp = b.timestampMillis.compareTo(a.timestampMillis);
        return (cmp != 0) ? cmp : b.topoheight.compareTo(a.topoheight);
      });
    }
  }
  // Otherwise, we assume the input is already sorted by timestamp in descending order.

  // Sort the dates in descending order
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  final out = <DateTime, List<wallet_flutter.XelisWalletTransactionEntry>>{};
  for (final k in sortedKeys) {
    out[k] = grouped[k]!;
  }

  return out;
}

TransactionDisplayInfo parseTxInfo(
  AppLocalizations loc,
  wallet_flutter.XelisNetwork network,
  wallet_flutter.XelisWalletTransactionEntryData type,
  LinkedHashMap<String, wallet_flutter.XelisWalletAssetMetadata> knownAssets,
  Map<String, wallet_flutter.XelisAddressBookEntry> addressBook, {
  List<wallet_flutter.XelisAddressBookEntry?> exactDestinations = const [],
}) {
  switch (type) {
    case wallet_flutter.XelisWalletCoinbaseEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.star,
        color: Colors.amber,
        label: loc.coinbase,
        details: '+${formatXelis(type.reward, network)}',
      );
    case wallet_flutter.XelisWalletBurnEntry():
      final asset = knownAssets[type.asset];
      return TransactionDisplayInfo(
        icon: FLucideIcons.flame,
        color: Colors.orange,
        label: loc.burn,
        subtitle: truncateText(type.asset, maxLength: 16),
        details: asset != null
            ? '-${formatCoin(type.amount, asset.decimals, asset.ticker)}'
            : loc.unknown_asset,
      );
    case wallet_flutter.XelisWalletIncomingEntry():
      String? subtitle;
      String? detailsMessage;
      String? badgeLabel;
      String? badgeSemanticLabel;
      final hasAttachedData = type.transfers.any(
        (transfer) => transfer.extraData != null,
      );
      if (type.transfers.isEmpty) {
        detailsMessage = loc.no_transfers_found;
      } else {
        subtitle = loc.transfer_from(getAddressLabel(type.from, addressBook));
        final summary = _summarizeTransfers(
          knownAssets,
          type.transfers.map(
            (transfer) => _TransferAmount(
              assetHash: transfer.asset,
              amount: transfer.amount,
            ),
          ),
          sign: '+',
        );
        detailsMessage = summary.details;
        badgeLabel = summary.badgeLabel;
        badgeSemanticLabel = _additionalAssetsSemanticLabel(
          loc,
          summary.additionalAssetCount,
        );
      }
      return TransactionDisplayInfo(
        icon: FLucideIcons.arrowDownLeft,
        color: Colors.greenAccent.shade400,
        label: loc.transfer_received,
        subtitle: subtitle,
        details: detailsMessage,
        badgeLabel: badgeLabel,
        badgeSemanticLabel: badgeSemanticLabel,
        attachedDataBadgeLabel: hasAttachedData
            ? loc.attached_data_badge
            : null,
        attachedDataSemanticLabel: hasAttachedData ? loc.attached_data : null,
      );
    case wallet_flutter.XelisWalletOutgoingEntry():
      String? subtitle;
      String? detailsMessage;
      String? badgeLabel;
      String? badgeSemanticLabel;
      final hasAttachedData = type.transfers.any(
        (transfer) => transfer.extraData != null,
      );
      if (type.transfers.isEmpty) {
        subtitle = loc.no_transfers_found;
      } else {
        if (type.transfers.length > 1) {
          subtitle = loc.multiple_transfers_sent;
        } else {
          final transfer = type.transfers.first;
          final exactDestination = exactDestinations.isEmpty
              ? null
              : exactDestinations.first;
          subtitle = loc.transfer_to(
            exactDestination?.displayName ??
                (transfer.extraData == null
                    ? getAddressLabel(transfer.destination, addressBook)
                    : truncateText(transfer.destination, maxLength: 8)),
          );
        }
        final summary = _summarizeTransfers(
          knownAssets,
          type.transfers.map(
            (transfer) => _TransferAmount(
              assetHash: transfer.asset,
              amount: transfer.amount,
            ),
          ),
          sign: '-',
        );
        detailsMessage = summary.details;
        badgeLabel = summary.badgeLabel;
        badgeSemanticLabel = _additionalAssetsSemanticLabel(
          loc,
          summary.additionalAssetCount,
        );
      }

      return TransactionDisplayInfo(
        icon: FLucideIcons.arrowUpRight,
        color: Colors.redAccent.shade200,
        label: loc.transfer_sent,
        subtitle: subtitle,
        details: detailsMessage,
        badgeLabel: badgeLabel,
        badgeSemanticLabel: badgeSemanticLabel,
        attachedDataBadgeLabel: hasAttachedData
            ? loc.attached_data_badge
            : null,
        attachedDataSemanticLabel: hasAttachedData ? loc.attached_data : null,
      );
    case wallet_flutter.XelisWalletMultisigEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.users,
        color: Colors.blueAccent.shade200,
        label: loc.multisig,
        subtitle: type.participants.isEmpty ? loc.disabled : loc.enabled,
      );
    case wallet_flutter.XelisWalletInvokeContractEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.squareCode,
        color: Colors.deepPurple,
        label: loc.tx_contract_invocation,
        subtitle: truncateText(type.contract, maxLength: 16),
      );
    case wallet_flutter.XelisWalletDeployContractEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.scrollText,
        color: Colors.teal,
        label: loc.tx_contract_deployment,
      );
    case wallet_flutter.XelisWalletIncomingContractEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.arrowDownToLine,
        color: Colors.purple.shade300,
        label: loc.tx_contract_transfer,
      );
    case wallet_flutter.XelisWalletIncomingBlobEntry():
      return _blobDisplayInfo(
        loc,
        type.data,
        direction: loc.incoming,
        icon: FLucideIcons.arrowDownLeft,
      );
    case wallet_flutter.XelisWalletOutgoingBlobEntry():
      return _blobDisplayInfo(
        loc,
        type.data,
        direction: loc.outgoing,
        icon: FLucideIcons.arrowUpRight,
      );
  }
}

TransactionDisplayInfo _blobDisplayInfo(
  AppLocalizations loc,
  wallet_flutter.XelisWalletExtraData data, {
  required String direction,
  required IconData icon,
}) {
  final parsed = ParsedExtraData.parse(loc, data);
  final details = [
    parsed.flag.name.capitalize(),
    parsed.label,
    ?parsed.fmtSize,
  ].join(' • ');

  return TransactionDisplayInfo(
    icon: icon,
    color: Colors.cyan.shade400,
    label: loc.blob,
    subtitle: direction,
    details: details,
  );
}

_TransferSummary _summarizeTransfers(
  Map<String, wallet_flutter.XelisWalletAssetMetadata> knownAssets,
  Iterable<_TransferAmount> transfers, {
  required String sign,
}) {
  final amountsByAsset = <String, BigInt>{};
  for (final transfer in transfers) {
    amountsByAsset.update(
      transfer.assetHash,
      (amount) => amount + transfer.amount,
      ifAbsent: () => transfer.amount,
    );
  }

  final firstTransfer = amountsByAsset.entries.first;
  final formattedData = getFormattedAssetNameAndAmount(
    knownAssets,
    firstTransfer.key,
    firstTransfer.value,
  );
  final additionalAssetCount = amountsByAsset.length - 1;

  return _TransferSummary(
    details: '$sign${formattedData.$2}',
    additionalAssetCount: additionalAssetCount,
  );
}

String? _additionalAssetsSemanticLabel(AppLocalizations loc, int count) {
  if (count <= 0) {
    return null;
  }

  final assetLabel = count == 1 ? loc.asset : loc.assets;
  return '$count $assetLabel';
}

String getAddressLabel(
  String address,
  Map<String, wallet_flutter.XelisAddressBookEntry> addressBook,
) {
  final contact = addressBook[address];
  if (contact != null && contact.displayName.isNotEmpty) {
    return contact.displayName;
  } else {
    return truncateText(address, maxLength: 8);
  }
}

class TransactionDisplayInfo {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final String? details;
  final String? badgeLabel;
  final String? badgeSemanticLabel;
  final String? attachedDataBadgeLabel;
  final String? attachedDataSemanticLabel;

  TransactionDisplayInfo({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.details,
    this.badgeLabel,
    this.badgeSemanticLabel,
    this.attachedDataBadgeLabel,
    this.attachedDataSemanticLabel,
  });

  bool get hasAttachedData => attachedDataBadgeLabel != null;
}

class TransactionAttachedDataBadge extends StatelessWidget {
  const TransactionAttachedDataBadge({required this.info, super.key});

  final TransactionDisplayInfo info;

  @override
  Widget build(BuildContext context) {
    final label = info.attachedDataBadgeLabel;
    if (label == null) {
      return const SizedBox.shrink();
    }

    return FTooltip(
      tipBuilder: (context, controller) =>
          Text(info.attachedDataSemanticLabel ?? label),
      child: Semantics(
        label: info.attachedDataSemanticLabel,
        child: FBadge(variant: .secondary, child: Text(label)),
      ),
    );
  }
}

class TransactionInfoSuffix extends StatelessWidget {
  const TransactionInfoSuffix({required this.info, super.key});

  final TransactionDisplayInfo info;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (info.hasAttachedData) TransactionAttachedDataBadge(info: info),
        if (info.badgeLabel != null)
          FTooltip(
            tipBuilder: (context, controller) =>
                Text(info.badgeSemanticLabel ?? info.badgeLabel!),
            child: Semantics(
              label: info.badgeSemanticLabel,
              child: FBadge(variant: .secondary, child: Text(info.badgeLabel!)),
            ),
          ),
        const Icon(FLucideIcons.chevronRight),
      ],
    );
  }
}

class _TransferAmount {
  const _TransferAmount({required this.assetHash, required this.amount});

  final String assetHash;
  final BigInt amount;
}

/// Converts native wallet milliseconds at the presentation boundary.
DateTime walletTimestampToDateTime(BigInt timestampMillis) {
  final minMillis = BigInt.from(-8640000000000000);
  final maxMillis = BigInt.from(8640000000000000);
  if (timestampMillis < minMillis || timestampMillis > maxMillis) {
    throw ArgumentError.value(
      timestampMillis,
      'timestampMillis',
      'Must fit in Dart DateTime milliseconds',
    );
  }
  return DateTime.fromMillisecondsSinceEpoch(timestampMillis.toInt());
}

class _TransferSummary {
  const _TransferSummary({
    required this.details,
    required this.additionalAssetCount,
  });

  final String details;
  final int additionalAssetCount;

  String? get badgeLabel =>
      additionalAssetCount > 0 ? '+$additionalAssetCount' : null;
}
