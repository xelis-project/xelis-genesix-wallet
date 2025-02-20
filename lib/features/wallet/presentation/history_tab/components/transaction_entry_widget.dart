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
  late Icon icon;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    var topoheight = NumberFormat().format(widget.transactionEntry.topoheight);

    var labelThirdColumn = loc.amount;
    var contentThirdColumn = '';

    final entryType = widget.transactionEntry.txEntryType;

    switch (entryType) {
      case CoinbaseEntry():
        icon = Icon(Icons.square_rounded, size: 18);
        contentThirdColumn = '+${formatXelis(entryType.reward)}';
      case BurnEntry():
        icon = Icon(Icons.local_fire_department_rounded, size: 18);
        final fee = entryType.fee;
        if (entryType.asset == xelisAsset) {
          contentThirdColumn = '-${formatXelis(entryType.amount + fee)}';
        } else {
          // TODO: check asset decimal
          contentThirdColumn = entryType.amount.toString();
        }
      case IncomingEntry():
        icon = Icon(Icons.arrow_downward, size: 18);
        if (entryType.transfers.length == 1) {
          var transfer = entryType.transfers[0];
          if (transfer.asset == xelisAsset) {
            contentThirdColumn = '+${formatXelis(transfer.amount)}';
          } else {
            // TODO: check asset decimal
            contentThirdColumn = '+${transfer.amount.toString()}';
          }
        } else {
          contentThirdColumn = loc.multi_transfer;
        }
      case OutgoingEntry():
        icon = Icon(Icons.arrow_upward, size: 18);
        if (entryType.transfers.length == 1) {
          final transfer = entryType.transfers[0];
          final fee = entryType.fee;
          if (transfer.asset == xelisAsset) {
            contentThirdColumn = '-${formatXelis(transfer.amount + fee)}';
          } else {
            // TODO: check asset decimal
            contentThirdColumn = '-${transfer.amount.toString()}';
          }
        } else {
          contentThirdColumn = loc.multi_transfer;
        }
      case MultisigEntry():
        icon = Icon(Icons.arrow_upward, size: 18);
        labelThirdColumn = loc.type;
        contentThirdColumn =
            (entryType.participants.isEmpty)
                ? loc.multisig_deleted
                : loc.multisig_activated;
      case InvokeContractEntry():
        icon = Icon(Icons.arrow_upward, size: 18);
        labelThirdColumn = loc.type;
        contentThirdColumn = loc.invoked_contract;
      case DeployContractEntry():
        icon = Icon(Icons.arrow_upward, size: 18);
        labelThirdColumn = loc.type;
        contentThirdColumn = loc.deployed_contract;
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spaces.medium,
          Spaces.small,
          Spaces.medium,
          Spaces.small,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: Spaces.medium),
            Column(
              children: [
                Text(
                  loc.topoheight,
                  style: context.labelMedium?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(topoheight, style: context.bodyLarge),
              ],
            ),
            const Spacer(),
            Column(
              children: [
                Text(
                  labelThirdColumn,
                  style: context.labelMedium?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(contentThirdColumn, style: context.bodyLarge),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showTransactionEntry(widget.transactionEntry),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionEntry(TransactionEntry transactionEntry) {
    context.push(
      AuthAppScreen.transactionEntry.toPath,
      extra: TransactionEntryScreenExtra(transactionEntry),
    );
  }
}
