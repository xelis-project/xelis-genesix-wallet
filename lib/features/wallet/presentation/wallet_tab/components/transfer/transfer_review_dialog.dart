import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/address.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/logo.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class TransferReviewDialog extends ConsumerStatefulWidget {
  const TransferReviewDialog(this.transactionSummary, {super.key});

  final TransactionSummary transactionSummary;

  @override
  ConsumerState<TransferReviewDialog> createState() =>
      _TransferReviewDialogState();
}

class _TransferReviewDialogState extends ConsumerState<TransferReviewDialog> {
  bool _isBroadcast = false;
  late String _txHash;
  late String _asset;
  late Future<String> _formattedAmount;
  late String _formattedFee;
  late String _rawAddress;
  late Address _destination;
  late bool _isXelisTransfer;

  @override
  void initState() {
    super.initState();
    final transfer = widget.transactionSummary.getSingleTransfer();
    _asset = transfer.asset;
    _isXelisTransfer = _asset == AppResources.xelisAsset.hash;
    _txHash = widget.transactionSummary.hash;
    _rawAddress = transfer.destination;
    _destination = getAddress(rawAddress: _rawAddress);
    final amount = transfer.amount;
    final fee = widget.transactionSummary.fee;

    final walletRepository = ref.read(
        walletStateProvider.select((value) => value.nativeWalletRepository));

    const repositoryError = "Wallet repository is not available";
    _formattedAmount = walletRepository?.formatCoin(amount, _asset) ??
        Future.error(repositoryError);
    _formattedFee = formatXelis(fee);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

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
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(top: Spaces.medium),
              child: Padding(
                padding: const EdgeInsets.all(Spaces.medium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.asset,
                            style: context.bodyLarge!.copyWith(
                                color: context.moreColors.mutedColor)),
                        const SizedBox(height: Spaces.small),
                        _isXelisTransfer
                            ? Row(
                                children: [
                                  Logo(
                                    imagePath:
                                        AppResources.xelisAsset.imagePath!,
                                  ),
                                  const SizedBox(width: Spaces.extraSmall),
                                  Text(
                                    AppResources.xelisAsset.name,
                                    style: context.bodyLarge,
                                  ),
                                ],
                              )
                            : Text(truncateText(_asset)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.amount.capitalize(),
                            style: context.bodyLarge!.copyWith(
                                color: context.moreColors.mutedColor)),
                        const SizedBox(height: Spaces.small),
                        FutureBuilder(
                          future: _formattedAmount,
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.hasData) {
                              return SelectableText(snapshot.data!);
                            } else {
                              return Text('...');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spaces.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.fee,
                  style: context.bodyLarge!
                      .copyWith(color: context.moreColors.mutedColor),
                ),
                SelectableText(_formattedFee),
              ],
            ),
            const SizedBox(height: Spaces.small),
            Divider(),
            const SizedBox(height: Spaces.small),
            Text(loc.hash,
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(widget.transactionSummary.hash),
            const SizedBox(height: Spaces.small),
            if (_destination.isIntegrated) ...[
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
              const SizedBox(height: Spaces.extraSmall),
              SelectableText(_rawAddress),
              const SizedBox(height: Spaces.small),
            ],
            Text(loc.receiver,
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.extraSmall),
            Row(
              children: [
                HashiconWidget(
                  hash: _destination.address,
                  size: const Size(35, 35),
                ),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: SelectableText(_destination.address),
                ),
              ],
            ),
            if (_destination.isIntegrated) ...[
              const SizedBox(height: Spaces.small),
              Text(loc.payment_id,
                  style: context.bodyLarge!
                      .copyWith(color: context.moreColors.mutedColor)),
              const SizedBox(height: Spaces.extraSmall),
              SelectableText(_destination.data.toString()),
            ],
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
                  onPressed: () => startWithBiometricAuth(
                    ref,
                    callback: _broadcastTransfer,
                    reason: 'Please authenticate to broadcast the transaction',
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(loc.broadcast),
                ),
        ),
      ],
    );
  }

  Future<void> _broadcastTransfer(WidgetRef ref) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      ref.context.loaderOverlay.show();

      await ref.read(walletStateProvider.notifier).broadcastTx(hash: _txHash);

      setState(() {
        _isBroadcast = true;
      });

      ref
          .read(snackBarMessengerProvider.notifier)
          .showInfo(loc.transaction_broadcast_message);
    } on AnyhowException catch (e) {
      talker.error('Cannot broadcast transaction: $e');
      final xelisMessage = (e).message.split("\n")[0];
      ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
    } catch (e) {
      talker.error('Cannot broadcast transaction: $e');
      ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
    }

    if (ref.context.mounted) {
      ref.context.loaderOverlay.hide();
    }
  }
}
