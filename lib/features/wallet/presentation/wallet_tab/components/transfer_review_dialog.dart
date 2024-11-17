import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';

class TransferReviewDialog extends ConsumerStatefulWidget {
  const TransferReviewDialog(this.tx, {super.key});

  final TransactionSummary tx;

  @override
  ConsumerState<TransferReviewDialog> createState() =>
      _TransferReviewDialogState();
}

class _TransferReviewDialogState extends ConsumerState<TransferReviewDialog> {
  bool _isBroadcast = false;

  Future<void> _broadcastTransfer(BuildContext context, WidgetRef ref) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      context.loaderOverlay.show();

      await ref
          .read(walletStateProvider.notifier)
          .broadcastTx(hash: widget.tx.hash);

      setState(() {
        _isBroadcast = true;
      });

      ref
          .read(snackBarMessengerProvider.notifier)
          .showInfo(loc.transaction_broadcast_message);
    } catch (e) {
      ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
    }

    if (context.mounted) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    // TODO handle various assets
    final amount =
        widget.tx.transactionSummaryType.transferOutEntry!.first.amount;
    final total = amount + widget.tx.fee;

    final rawAddress =
        widget.tx.transactionSummaryType.transferOutEntry!.first.destination;
    final destination = splitIntegratedAddress(rawAddress);

    return GenericDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: Spaces.medium, top: Spaces.large),
            child: Text(
              loc.review,
              style: context.headlineSmall,
            ),
          ),
          if (!_isBroadcast)
            Padding(
              padding:
                  const EdgeInsets.only(right: Spaces.small, top: Spaces.small),
              child: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(toBeginningOfSentenceCase(loc.amount) ?? loc.amount,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                SelectableText(formatXelis(amount.truncate())),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.fee,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                SelectableText(formatXelis(widget.tx.fee)),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.total,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                SelectableText(formatXelis(total.truncate())),
              ],
            ),
            const SizedBox(height: Spaces.small),
            if (destination.isIntegrated) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(loc.destination,
                      style: context.bodyLarge!
                          .copyWith(color: context.moreColors.mutedColor)),
                  const SizedBox(width: Spaces.small),
                  Tooltip(
                    message: loc.integrated_address_detected,
                    textStyle: context.bodyMedium
                        ?.copyWith(color: context.colors.primary),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: context.moreColors.mutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spaces.small),
              SelectableText(rawAddress),
              const SizedBox(height: Spaces.small),
            ],
            Text(loc.receiver,
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.small),
            Row(
              children: [
                HashiconWidget(
                  hash: destination.address,
                  size: const Size(35, 35),
                ),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: SelectableText(destination.address),
                ),
              ],
            ),
            if (destination.isIntegrated) ...[
              const SizedBox(height: Spaces.small),
              Text(loc.payment_id,
                  style: context.bodyLarge!
                      .copyWith(color: context.moreColors.mutedColor)),
              const SizedBox(height: 3),
              SelectableText(destination.data.toString()),
            ],
            const SizedBox(height: Spaces.small),
            Text(loc.hash,
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: 3),
            SelectableText(widget.tx.hash),
          ],
        ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: _isBroadcast
              ? TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: Text(loc.ok_button),
                )
              : TextButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return PasswordDialog(
                          onValid: () => _broadcastTransfer(context, ref),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(loc.broadcast),
                ),
        ),
      ],
    );
  }
}
