import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/multisig/setup_multisig_dialog.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/multisig/sign_transaction_dialog.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'delete_multisig_dialog.dart';

class MultisigScreen extends ConsumerStatefulWidget {
  const MultisigScreen({super.key});

  @override
  ConsumerState createState() => _MultisigScreenState();
}

class _MultisigScreenState extends ConsumerState<MultisigScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState =
        ref.watch(walletStateProvider.select((value) => value.multisigState));
    final pendingState = ref.watch(multisigPendingStateProvider);
    return CustomScaffold(
      appBar: GenericAppBar(title: 'Multisig'),
      body: multisigState.isSetup
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spaces.large, Spaces.none, Spaces.large, Spaces.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spaces.large),
                  Text('Threshold',
                      style: context.labelLarge
                          ?.copyWith(color: context.moreColors.mutedColor)),
                  Text('minimum signatures required',
                      style: context.labelSmall?.copyWith(
                        color: context.moreColors.mutedColor,
                        fontStyle: FontStyle.italic,
                      )),
                  SelectableText(multisigState.threshold.toString()),
                  const SizedBox(height: Spaces.large),
                  Text('Topoheight',
                      style: context.labelLarge
                          ?.copyWith(color: context.moreColors.mutedColor)),
                  Text('multisig activation height',
                      style: context.labelSmall?.copyWith(
                        color: context.moreColors.mutedColor,
                        fontStyle: FontStyle.italic,
                      )),
                  SelectableText(multisigState.topoheight.toString()),
                  const SizedBox(height: Spaces.large),
                  Text(
                    'Participants',
                    style: context.labelLarge
                        ?.copyWith(color: context.moreColors.mutedColor),
                  ),
                  const Divider(),
                  ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(Spaces.medium,
                              Spaces.small, Spaces.medium, Spaces.small),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: Spaces.extraSmall),
                                    child: Text('ID',
                                        style: context.labelMedium?.copyWith(
                                            color:
                                                context.moreColors.mutedColor)),
                                  ),
                                  Text(multisigState.participants
                                      .elementAt(index)
                                      .id
                                      .toString()),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: Spaces.extraSmall),
                                    child: Text('Address',
                                        style: context.labelMedium?.copyWith(
                                            color:
                                                context.moreColors.mutedColor)),
                                  ),
                                  Tooltip(
                                    message: multisigState.participants
                                        .elementAt(index)
                                        .address,
                                    child: GestureDetector(
                                      child: Text(truncateText(
                                          multisigState.participants
                                              .elementAt(index)
                                              .address,
                                          maxLength: 20)),
                                      onTap: () => copyToClipboard(
                                          multisigState.participants
                                              .elementAt(index)
                                              .address,
                                          ref,
                                          loc.copied),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: multisigState.participants.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                  Spacer(),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(Spaces.medium /* + 4*/),
                        side: BorderSide(
                          color: context.colors.error,
                          width: 1,
                        ),
                      ),
                      onPressed: pendingState
                          ? () {}
                          : () => _showDeleteMultisigDialog(),
                      label: Text(
                        'Delete multisig configuration',
                        style: context.titleSmall!.copyWith(
                            color: context.colors.error,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('This wallet is not a multisig wallet',
                      style: context.titleMedium
                          ?.copyWith(color: context.moreColors.mutedColor)),
                  const SizedBox(height: Spaces.large),
                  TextButton(
                    onPressed: pendingState ? () {} : _showSetupMultisigDialog,
                    child: Text('Setup'),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSignTransactionDialog,
        tooltip: 'Sign transaction',
        child: const Icon(Icons.key),
      ),
    );
  }

  void _showSetupMultisigDialog() {
    showDialog<void>(
        context: context,
        builder: (context) {
          return SetupMultisigDialog();
        });
  }

  void _showDeleteMultisigDialog() async {
    context.loaderOverlay.show();

    final unsignedTx =
        await ref.read(walletStateProvider.notifier).startDeleteMultisig();

    if (mounted) {
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }

      if (unsignedTx != null) {
        showDialog<void>(
            context: context,
            builder: (context) {
              return DeleteMultisigDialog(unsignedTx);
            });
      } else {
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarMessengerProvider.notifier).showError(loc.oups);
      }
    }
  }

  void _showSignTransactionDialog() {
    showDialog<void>(
        context: context,
        builder: (context) {
          return SignTransactionDialog();
        });
  }
}
