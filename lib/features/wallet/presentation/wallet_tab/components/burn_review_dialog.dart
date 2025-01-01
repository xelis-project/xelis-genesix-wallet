import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/logo.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class BurnReviewDialog extends ConsumerStatefulWidget {
  const BurnReviewDialog(this.transactionSummary, {super.key});

  final TransactionSummary transactionSummary;

  @override
  ConsumerState createState() => _BurnReviewDialogState();
}

class _BurnReviewDialogState extends ConsumerState<BurnReviewDialog> {
  bool _isBroadcast = false;
  bool _isConfirmed = false;
  late String _asset;
  late Future<String> _formattedAmount;
  late Future<String> _formattedFee;
  late bool _isXelisTransfer;

  @override
  void initState() {
    super.initState();
    final burn = widget.transactionSummary.getBurn();
    _asset = burn.asset;
    _isXelisTransfer = _asset == AppResources.xelisAsset.hash;
    final amount = burn.amount;
    final fee = widget.transactionSummary.fee;

    final walletRepository = ref.read(
        walletStateProvider.select((value) => value.nativeWalletRepository));

    const repositoryError = "Wallet repository is not available";
    _formattedAmount = walletRepository?.formatCoin(amount, _asset) ??
        Future.error(repositoryError);
    _formattedFee = walletRepository?.formatCoin(fee, _asset) ??
        Future.error(repositoryError);
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  const SizedBox(width: Spaces.small),
                                  Text(AppResources.xelisAsset.name),
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
                Text(loc.fee,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                FutureBuilder(
                  future: _formattedFee,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      return SelectableText(
                          '${snapshot.data!} ${AppResources.xelisAsset.ticker}');
                    } else {
                      return Text("...");
                    }
                  },
                ),
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
            const SizedBox(height: Spaces.large),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animFast),
              child: _isBroadcast
                  ? SizedBox.shrink()
                  : FormBuilderCheckbox(
                      name: 'confirm',
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.only(top: Spaces.small),
                        isDense: true,
                        fillColor: Colors.transparent,
                      ),
                      title: Text(
                        loc.burn_confirmation,
                        style: context.bodyMedium,
                      ),
                      validator: FormBuilderValidators.required(),
                      onChanged: (value) {
                        setState(() {
                          _isConfirmed = value as bool;
                        });
                      },
                    ),
            ),
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
                  onPressed: _isConfirmed
                      ? () => startWithBiometricAuth(
                            ref,
                            callback: _broadcastBurn,
                            closeCurrentDialog: false,
                          )
                      : null,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(loc.broadcast),
                ),
        ),
      ],
    );
  }

  Future<void> _broadcastBurn(WidgetRef ref) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      ref.context.loaderOverlay.show();

      await ref
          .read(walletStateProvider.notifier)
          .broadcastTx(hash: widget.transactionSummary.hash);

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

    if (ref.context.mounted && ref.context.loaderOverlay.visible) {
      ref.context.loaderOverlay.hide();
    }
  }
}
