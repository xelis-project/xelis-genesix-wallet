import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BurnReviewDialog extends ConsumerStatefulWidget {
  const BurnReviewDialog(this.tx, {super.key});

  final TransactionSummary tx;

  @override
  ConsumerState createState() => _BurnReviewDialogState();
}

class _BurnReviewDialogState extends ConsumerState<BurnReviewDialog> {
  bool _isBroadcast = false;
  late String _asset;
  late Future<String> _formattedAmount;
  late Future<String> _formattedFee;
  late Future<String> _formattedTotal;

  @override
  void initState() {
    super.initState();
    _asset = widget.tx.transactionSummaryType.burn!.asset;
    final amount = widget.tx.transactionSummaryType.burn!.amount;
    final total = widget.tx.fee + amount;

    final walletRepository = ref.read(
        walletStateProvider.select((value) => value.nativeWalletRepository));

    const repositoryError = "Wallet repository is null";
    _formattedAmount = walletRepository?.formatCoin(amount, _asset) ??
        Future.error(repositoryError);
    _formattedFee = walletRepository?.formatCoin(widget.tx.fee, _asset) ??
        Future.error(repositoryError);
    _formattedTotal = walletRepository?.formatCoin(total, _asset) ??
        Future.error(repositoryError);
  }

  Future<void> _broadcastBurn(BuildContext context, WidgetRef ref) async {
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

    if (context.mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return AlertDialog(
      scrollable: true,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.review,
              style: context.headlineSmall,
            ),
            const SizedBox(height: Spaces.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(toBeginningOfSentenceCase(loc.amount) ?? loc.amount,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                FutureBuilder(
                  future: _formattedAmount,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      return SelectableText(snapshot.data!);
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.fee,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                FutureBuilder(
                  future: _formattedFee,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      return SelectableText(snapshot.data!);
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.total,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                FutureBuilder(
                  future: _formattedTotal,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      return SelectableText(snapshot.data!);
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: Spaces.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.asset,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                Text(_asset == xelisAsset ? 'XELIS' : truncateText(_asset)),
              ],
            ),
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
        if (!_isBroadcast)
          TextButton(
            onPressed: () {
              ref
                  .read(walletStateProvider.notifier)
                  .cancelTransaction(hash: widget.tx.hash);
              context.pop();
            },
            child: Text(loc.cancel_button),
          ),
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
                          onValid: () => _broadcastBurn(context, ref),
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
