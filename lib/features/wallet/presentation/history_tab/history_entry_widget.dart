import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class HistoryEntry extends StatelessWidget {
  const HistoryEntry({super.key, required this.txEntry});

  final TxEntry txEntry;

  String _getTitle(EntryData entryData) {
    if (entryData.coinbase != null) {
      return 'Coinbase';
    } else if (entryData.burn != null) {
      return 'Burn';
    } else if (entryData.incoming != null) {
      return 'Incoming';
    } else if (entryData.outgoing != null) {
      return 'Outgoing';
    } else {
      return 'Unknown';
    }
  }

  Widget _getDetails(BuildContext context, EntryData entryData) {
    if (entryData.coinbase != null) {
      return Text(
        'Amount: ${entryData.coinbase! / pow(10, 5)} XELIS',
        style: context.bodyMedium,
      );
    } else if (entryData.burn != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset: ${entryData.burn!.asset}', style: context.bodyMedium),
          Text('Amount: ${entryData.burn!.amount}', style: context.bodyMedium),
        ],
      );
    } else if (entryData.incoming != null) {
      final count = entryData.incoming!.transfers.length;
      final summary = <String, int>{};
      for (final transfer in entryData.incoming!.transfers) {
        summary.update(
          transfer.asset!,
          (value) => value + transfer.amount!,
          ifAbsent: () => transfer.amount!,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From: ${entryData.incoming!.owner}',
            style: context.bodyMedium,
          ),
          Text(
            'Number of transfers: $count',
            style: context.bodyMedium,
          ),
          ...summary.entries.map(
            (entry) => Text(
              'Asset: ${entry.key}\nAmount: ${entry.value}',
              style: context.bodyMedium,
            ),
          ),
        ],
      );
    } else if (entryData.outgoing != null) {
      final count = entryData.outgoing!.transfers.length;
      final summary = <String, int>{};
      for (final transfer in entryData.outgoing!.transfers) {
        summary.update(
          transfer.asset!,
          (value) => value + transfer.amount!,
          ifAbsent: () => transfer.amount!,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Number of transfers: $count',
            style: context.bodyMedium,
          ),
          ...summary.entries.map(
            (entry) => Text(
              'Asset: ${entry.key}\nAmount: ${entry.value}',
              style: context.bodyMedium,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getTitle(txEntry.entryData!);
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hash: ${txEntry.hash}',
              style: context.bodyMedium,
            ),
            Text(
              'Topoheight: ${txEntry.topoHeight}',
              style: context.bodyMedium,
            ),
            _getDetails(context, txEntry.entryData!),
          ],
        ),
      ),
    );
  }
}
