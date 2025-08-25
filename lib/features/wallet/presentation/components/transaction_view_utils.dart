import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:forui/assets.dart';
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

  final out = LinkedHashMap<DateTime, List<TransactionEntry>>();
  for (final k in sortedKeys) {
    out[k] = grouped[k]!;
  }

  return out;
}

// TODO: Localize this function
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
        icon: FIcons.star,
        color: Colors.amber,
        label: loc.coinbase,
        details: '+${formatXelis(type.reward, network)}',
      );
    case BurnEntry():
      final asset = knownAssets[type.asset];
      return TransactionDisplayInfo(
        icon: FIcons.flame,
        color: Colors.orange,
        label: loc.burn,
        subtitle: truncateText(type.asset, maxLength: 16),
        details: asset != null
            ? '-${formatCoin(type.amount, asset.decimals, asset.ticker)}'
            : 'Unknown Asset',
      );
    case IncomingEntry():
      String? subtitle;
      String? detailsMessage;
      if (type.transfers.length > 1) {
        detailsMessage = 'Multiple transfers received';
      } else if (type.transfers.isEmpty) {
        detailsMessage = 'No transfers found';
      } else {
        final transfer = type.transfers.first;
        final asset = knownAssets[transfer.asset];
        if (asset != null) {
          subtitle = 'from ${getAddressLabel(type.from, addressBook)}';
          detailsMessage =
              '+${formatCoin(transfer.amount, asset.decimals, asset.ticker)}';
        } else {
          subtitle = 'Unknown Asset';
        }
      }
      return TransactionDisplayInfo(
        icon: FIcons.arrowDownLeft,
        color: Colors.greenAccent.shade400,
        label: 'Received',
        subtitle: subtitle,
        details: detailsMessage,
      );
    case OutgoingEntry():
      String? subtitle;
      String? detailsMessage;
      if (type.transfers.length > 1) {
        subtitle = 'Multiple transfers sent';
      } else if (type.transfers.isEmpty) {
        subtitle = 'No transfers found';
      } else {
        final transfer = type.transfers.first;
        final asset = knownAssets[transfer.asset];
        if (asset != null) {
          subtitle = 'to ${getAddressLabel(transfer.destination, addressBook)}';
          detailsMessage =
              '-${formatCoin(transfer.amount, asset.decimals, asset.ticker)}';
        } else {
          subtitle = 'Unknown Asset';
        }
      }

      return TransactionDisplayInfo(
        icon: FIcons.arrowUpRight,
        color: Colors.redAccent.shade200,
        label: 'Sent',
        subtitle: subtitle,
        details: detailsMessage,
      );
    case MultisigEntry():
      return TransactionDisplayInfo(
        icon: FIcons.users,
        color: Colors.blueAccent.shade200,
        label: loc.multisig,
        subtitle: type.participants.isEmpty ? 'Disabled' : 'Enabled',
      );
    case InvokeContractEntry():
      return TransactionDisplayInfo(
        icon: FIcons.squareCode,
        color: Colors.deepPurple,
        label: 'Contract Invocation',
        subtitle: truncateText(type.contract, maxLength: 16),
      );
    case DeployContractEntry():
      return TransactionDisplayInfo(
        icon: FIcons.scrollText,
        color: Colors.teal,
        label: 'Contract Deployment',
      );
  }
}

String getAddressLabel(
  String address,
  Map<String, ContactDetails> addressBook,
) {
  final contact = addressBook[address];
  if (contact != null && contact.name.isNotEmpty) {
    return contact.name;
  } else {
    return truncateText(address, maxLength: 16);
  }
}

class TransactionDisplayInfo {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final String? details;

  TransactionDisplayInfo({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.details,
  });
}
