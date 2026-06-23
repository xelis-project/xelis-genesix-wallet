import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;

Map<DateTime, List<TransactionEntry>> groupTransactionsByDateSorted2Levels(
  List<TransactionEntry> transactions, {
  bool useUtc = false,
  bool assumeInputAlreadyDescByTime = false,
}) {
  final Map<DateTime, List<TransactionEntry>> grouped = {};

  DateTime dateOnly(DateTime dt) {
    // Avoid using toLocal() if already in local time; normalize to Y/M/D
    final d = useUtc ? dt.toUtc() : dt;
    return DateTime(d.year, d.month, d.day);
  }

  // Group transactions by date
  for (final tx in transactions) {
    final ts = tx.timestamp;
    if (ts == null) continue;

    final key = dateOnly(ts);
    final list = grouped.putIfAbsent(key, () => <TransactionEntry>[]);
    list.add(tx);
  }

  // If the input is already sorted by timestamp in descending order,
  // we can skip the sorting step.
  if (!assumeInputAlreadyDescByTime) {
    for (final list in grouped.values) {
      list.sort((a, b) {
        final ta = a.timestamp;
        final tb = b.timestamp;
        if (ta == null && tb == null) {
          return b.topoheight.compareTo(a.topoheight);
        } else if (ta == null) {
          return 1; // nulls last
        } else if (tb == null) {
          return -1;
        }
        final cmp = tb.compareTo(ta); // desc
        return (cmp != 0) ? cmp : b.topoheight.compareTo(a.topoheight);
      });
    }
  }
  // Otherwise, we assume the input is already sorted by timestamp in descending order.

  // Sort the dates in descending order
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  final out = <DateTime, List<TransactionEntry>>{};
  for (final k in sortedKeys) {
    out[k] = grouped[k]!;
  }

  return out;
}

TransactionDisplayInfo parseTxInfo(
  AppLocalizations loc,
  rust.Network network,
  TransactionEntryType type,
  LinkedHashMap<String, AssetData> knownAssets,
  Map<String, ContactDetails> addressBook,
) {
  switch (type) {
    case CoinbaseEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.star,
        color: Colors.amber,
        label: loc.coinbase,
        details: '+${formatXelis(type.reward, network)}',
      );
    case BurnEntry():
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
    case IncomingEntry():
      String? subtitle;
      String? detailsMessage;
      String? badgeLabel;
      String? badgeSemanticLabel;
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
      );
    case OutgoingEntry():
      String? subtitle;
      String? detailsMessage;
      String? badgeLabel;
      String? badgeSemanticLabel;
      if (type.transfers.isEmpty) {
        subtitle = loc.no_transfers_found;
      } else {
        if (type.transfers.length > 1) {
          subtitle = loc.multiple_transfers_sent;
        } else {
          final transfer = type.transfers.first;
          subtitle = loc.transfer_to(
            getAddressLabel(transfer.destination, addressBook),
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
      );
    case MultisigEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.users,
        color: Colors.blueAccent.shade200,
        label: loc.multisig,
        subtitle: type.participants.isEmpty ? loc.disabled : loc.enabled,
      );
    case InvokeContractEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.squareCode,
        color: Colors.deepPurple,
        label: loc.tx_contract_invocation,
        subtitle: truncateText(type.contract, maxLength: 16),
      );
    case DeployContractEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.scrollText,
        color: Colors.teal,
        label: loc.tx_contract_deployment,
      );
    case IncomingContractEntry():
      return TransactionDisplayInfo(
        icon: FLucideIcons.arrowDownToLine,
        color: Colors.purple.shade300,
        label: loc.tx_contract_transfer,
      );
    case BlobEntry():
      final parsed = ParsedExtraData.parse(loc, type.data);
      return TransactionDisplayInfo(
        icon: FLucideIcons.fileText,
        color: Colors.cyan.shade400,
        label: loc.blob,
        subtitle: loc.extra_data,
        details:
            '${parsed.flag.name.capitalize()} • ${parsed.label} • ${parsed.fmtSize}',
      );
  }
}

_TransferSummary _summarizeTransfers(
  Map<String, AssetData> knownAssets,
  Iterable<_TransferAmount> transfers, {
  required String sign,
}) {
  final amountsByAsset = <String, int>{};
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
  Map<String, ContactDetails> addressBook,
) {
  final contact = addressBook[address];
  if (contact != null && contact.name.isNotEmpty) {
    return contact.name;
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

  TransactionDisplayInfo({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.details,
    this.badgeLabel,
    this.badgeSemanticLabel,
  });
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
  final int amount;
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
