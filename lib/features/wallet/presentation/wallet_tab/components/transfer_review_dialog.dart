import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/native_transaction.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:random_avatar/random_avatar.dart';

class TransferReviewDialog extends ConsumerWidget {
  final String address;
  final String amount;
  final NativeTransaction tx;

  const TransferReviewDialog(this.address, this.amount, this.tx, {super.key});

  void _sendTransfer(BuildContext context, WidgetRef ref) async {
    try {
      context.loaderOverlay.show();

      await ref.read(walletStateProvider.notifier).broadcastTx(tx: tx);
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
    var amountValue = double.parse(amount) * pow(10, AppResources.xelisDecimals);
    var total = amountValue + tx.fee;

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
                SelectableText(formatXelis(amountValue.truncate())),
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
                RandomAvatar(address, width: 35, height: 35),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: SelectableText(address),
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
            context.pop();
          },
          child: Text('Cancel'),
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
          label: Text('Broadcast'),
        ),
      ],
    );
  }
}
