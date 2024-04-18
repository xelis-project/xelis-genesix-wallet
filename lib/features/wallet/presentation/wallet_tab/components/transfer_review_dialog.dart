import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:random_avatar/random_avatar.dart';

class TransferReviewDialog extends ConsumerWidget {
  final TransactionSummary tx;

  const TransferReviewDialog(this.tx, {super.key});

  void _sendTransfer(BuildContext context, WidgetRef ref) async {
    try {
      context.loaderOverlay.show();

      await ref.read(walletStateProvider.notifier).broadcastTx(hash: tx.hash);
      ref
          .read(snackBarMessengerProvider.notifier)
          .showInfo('The transaction was broadcast to the network.');
    } catch (e) {
      ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
    }

    if (context.mounted) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination =
        tx.transactionSummaryType.transferOutEntry!.first.destination;
    var total = tx.amount + tx.fee;

    return AlertDialog(
      scrollable: true,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review',
              style: context.headlineSmall,
            ),
            const SizedBox(height: Spaces.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount',
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                SelectableText(formatXelis(tx.amount.truncate())),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fee',
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                SelectableText(formatXelis(tx.fee)),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                SelectableText(formatXelis(total.truncate())),
              ],
            ),
            const SizedBox(height: Spaces.small),
            Text('Receiver',
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.small),
            Row(
              children: [
                RandomAvatar(destination, width: 35, height: 35),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: SelectableText(destination),
                ),
              ],
            ),
            const SizedBox(height: Spaces.small),
            Text('Hash',
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: 3),
            SelectableText(tx.hash),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref
                .read(walletStateProvider.notifier)
                .cancelTransaction(hash: tx.hash);
            context.pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return PasswordDialog(
                  onValid: () async {
                    _sendTransfer(context, ref);
                  },
                );
              },
            );
          },
          icon: const Icon(Icons.send),
          label: const Text('Broadcast'),
        ),
      ],
    );
  }
}
