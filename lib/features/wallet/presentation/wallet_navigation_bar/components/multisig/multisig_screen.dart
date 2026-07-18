import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/multisig/setup_multisig_dialog.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/multisig/sign_transaction_dialog.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transaction_review_dialog_new.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:go_router/go_router.dart';

class MultisigScreen extends ConsumerStatefulWidget {
  const MultisigScreen({super.key});

  @override
  ConsumerState createState() => _MultisigScreenState();
}

class _MultisigScreenState extends ConsumerState<MultisigScreen> {
  var _isDeletingMultisig = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState = ref.watch(
      walletRuntimeProvider.select((value) => value.multisigState),
    );
    final pendingState = ref.watch(multisigPendingStateProvider);
    return CustomScaffold(
      appBar: FHeader.nested(
        title: Text(loc.multisig),
        suffixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.x(onPress: () => context.pop()),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        key: ValueKey<bool>(pendingState),
        duration: const Duration(milliseconds: AppDurations.animFast),
        child: pendingState
            ? Center(
                child: Text(
                  loc.changes_in_progress,
                  style: context.titleMedium,
                ),
              )
            : multisigState.isSetup
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spaces.large,
                  Spaces.none,
                  Spaces.large,
                  Spaces.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Spaces.large),
                    Text(
                      loc.threshold,
                      style: context.labelLarge?.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      loc.minimum_signatures_required.toLowerCase(),
                      style: context.labelSmall?.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SelectableText(multisigState.threshold.toString()),
                    const SizedBox(height: Spaces.large),
                    Text(
                      loc.topoheight,
                      style: context.labelLarge?.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      loc.multisig_activation_height.toLowerCase(),
                      style: context.labelSmall?.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SelectableText(multisigState.topoheight.toString()),
                    const SizedBox(height: Spaces.large),
                    Text(
                      loc.participants,
                      style: context.labelLarge?.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: Spaces.small,
                            ),
                            child: AppCard(
                              child: Table(
                                columnWidths: {
                                  0: FixedColumnWidth(Spaces.extraLarge),
                                  1: FlexColumnWidth(),
                                },
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                children: [
                                  TableRow(
                                    children: [
                                      Text(
                                        loc.id,
                                        style: context.labelMedium?.copyWith(
                                          color: context
                                              .theme
                                              .colors
                                              .mutedForeground,
                                        ),
                                      ),
                                      Text(
                                        loc.address,
                                        style: context.labelMedium?.copyWith(
                                          color: context
                                              .theme
                                              .colors
                                              .mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      Text(
                                        multisigState.participants
                                            .elementAt(index)
                                            .id
                                            .toString(),
                                      ),
                                      FTooltip(
                                        tipBuilder: (context, controller) =>
                                            Text(
                                              multisigState.participants
                                                  .elementAt(index)
                                                  .address,
                                            ),
                                        child: GestureDetector(
                                          child: AddressWidget(
                                            multisigState.participants
                                                .elementAt(index)
                                                .address,
                                          ),
                                          onTap: () => copyToClipboard(
                                            multisigState.participants
                                                .elementAt(index)
                                                .address,
                                            ref,
                                            loc.copied,
                                          ),
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
                    ),
                    Center(
                      child: FButton(
                        variant: .destructive,
                        onPress: _isDeletingMultisig
                            ? null
                            : _showDeleteMultisigDialog,
                        prefix: _isDeletingMultisig
                            ? const FCircularProgress.loader()
                            : Icon(FLucideIcons.trash2),
                        child: Text(loc.delete_multisig_configuration),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spaces.large,
                    Spaces.none,
                    Spaces.large,
                    Spaces.large,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${loc.multisig_intro_message_1}\n${loc.multisig_intro_message_2}',
                        style: context.titleMedium?.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      Spacer(),
                      Text(
                        loc.no_multisig_configuration_found,
                        style: context.titleSmall?.copyWith(
                          color: context.colors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: Spaces.medium),
                      FButton(
                        onPress: _showSetupMultisigDialog,
                        child: Text(loc.setup),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FTooltip(
        tipBuilder: (context, controller) => Text(loc.sign_transaction),
        child: FButton.icon(
          semanticsLabel: loc.sign_transaction,
          onPress: _showSignTransactionDialog,
          child: const Icon(FLucideIcons.key),
        ),
      ),
    );
  }

  void _showSetupMultisigDialog() {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return SetupMultisigDialog(style: style, animation: animation);
      },
    );
  }

  void _showDeleteMultisigDialog() async {
    if (_isDeletingMultisig) return;

    setState(() => _isDeletingMultisig = true);

    final String? unsignedTx;
    try {
      unsignedTx = await ref.read(walletCommandsProvider).startDeleteMultisig();
    } finally {
      if (mounted) {
        setState(() => _isDeletingMultisig = false);
      }
    }

    if (mounted) {
      if (unsignedTx != null) {
        ref
            .read(transactionReviewProvider.notifier)
            .signaturePending(unsignedTx);

        showAppDialog<void>(
          context: context,
          builder: (dialogContext, _, animation) {
            return TransactionReviewDialogNew(animation);
          },
        );
      } else {
        final loc = ref.read(appLocalizationsProvider);
        ref.read(toastProvider.notifier).showError(description: loc.oups);
      }
    }
  }

  void _showSignTransactionDialog() {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return SignTransactionDialog(style: style, animation: animation);
      },
    );
  }
}
