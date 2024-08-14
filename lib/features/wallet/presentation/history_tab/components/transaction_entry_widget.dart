import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_screen.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';

class TransactionEntryWidget extends ConsumerStatefulWidget {
  const TransactionEntryWidget({required this.transactionEntry, super.key});

  final TransactionEntry transactionEntry;

  @override
  ConsumerState<TransactionEntryWidget> createState() =>
      _TransactionEntryWidgetState();
}

class _TransactionEntryWidgetState
    extends ConsumerState<TransactionEntryWidget> {
  void _showTransactionEntry(
      BuildContext context, TransactionEntry transactionEntry) {
    context.push(
      AppScreen.transactionEntry.toPath,
      extra: TransactionEntryScreenExtra(transactionEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    var displayTopoheight =
        NumberFormat().format(widget.transactionEntry.topoHeight);
    var displayAmount = '';

    final entryType = widget.transactionEntry.txEntryType;

    switch (entryType) {
      case CoinbaseEntry():
        displayAmount = '+${formatXelis(entryType.reward)} XEL';
      case BurnEntry():
        if (entryType.asset == xelisAsset) {
          displayAmount = '-${formatXelis(entryType.amount)} XEL';
        } else {
          // TODO: check asset decimal
          displayAmount = entryType.amount.toString();
        }
      case IncomingEntry():
        if (entryType.transfers.length == 1) {
          var transfer = entryType.transfers[0];
          if (transfer.asset == xelisAsset) {
            displayAmount = '+${formatXelis(transfer.amount)} XEL';
          } else {
            // TODO: check asset decimal
            displayAmount = '+${transfer.amount.toString()}';
          }
        } else {
          displayAmount = loc.multi_transfer;
        }
      case OutgoingEntry():
        if (entryType.transfers.length == 1) {
          var transfer = entryType.transfers[0];
          if (transfer.asset == xelisAsset) {
            displayAmount = '-${formatXelis(transfer.amount)} XEL';
          } else {
            // TODO: check asset decimal
            displayAmount = '-${transfer.amount.toString()}';
          }
        } else {
          displayAmount = loc.multi_transfer;
        }
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spaces.medium, Spaces.small, Spaces.medium, Spaces.small),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.topoheight, style: context.labelMedium
                    //?.copyWith(color: context.colors.primary),
                    ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  displayTopoheight,
                  style: context.bodyLarge,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.amount,
                    /*_transferEntry == null ||
                            _transferEntry?.asset == xelisAsset
                        ? loc.amount.capitalize
                        : '${loc.amount.capitalize} (${loc.atomic_units})',*/
                    style: context.labelMedium
                    //?.copyWith(color: context.colors.primary),
                    ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  displayAmount,
                  style: context.bodyLarge,
                ),
              ],
            ),
            IconButton(
                onPressed: () {
                  _showTransactionEntry(context, widget.transactionEntry);
                },
                icon: const Icon(
                  Icons.info_outline_rounded,
                  //size: 18,
                )),
          ],
        ),
      ),
    );
  }
}
