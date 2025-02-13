import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_participant.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class TransactionDialog extends ConsumerStatefulWidget {
  const TransactionDialog(this.reviewContent, {super.key});

  final Widget reviewContent;

  @override
  ConsumerState createState() => _TransactionDialogState();
}

class _TransactionDialogState extends ConsumerState<TransactionDialog> {
  final _signaturesFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_signaturesFormKey',
  );

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState = ref.watch(
      walletStateProvider.select((value) => value.multisigState),
    );
    final transactionReview = ref.watch(transactionReviewProvider);
    return GenericDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: Spaces.medium,
              top: Spaces.large,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animFast),
              child: Text(
                key: ValueKey(transactionReview.transactionHashToSign),
                transactionReview.hasSummary ? loc.review : loc.multisig,
                style: context.headlineSmall,
              ),
            ),
          ),
          if (!transactionReview.isBroadcast)
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
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
        constraints: BoxConstraints(maxWidth: 600),
        child:
            !transactionReview.hasSummary
                ? Column(
                  key: ValueKey(transactionReview.transactionHashToSign),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.transaction_hash_to_sign,
                          style: context.titleMedium?.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => copyToClipboard(
                                transactionReview.transactionHashToSign!,
                                ref,
                                loc.copied,
                              ),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: loc.copy_hash_transaction,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spaces.small),
                    SelectableText(transactionReview.transactionHashToSign!),
                    const SizedBox(height: Spaces.small),
                    Divider(),
                    const SizedBox(height: Spaces.small),
                    Text(
                      loc.multisig_barrier_message,
                      style: context.labelMedium?.copyWith(
                        color: context.moreColors.mutedColor,
                      ),
                    ),
                    const SizedBox(height: Spaces.large),
                    FormBuilder(
                      key: _signaturesFormKey,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  loc.participant_id,
                                  style: context.labelMedium?.copyWith(
                                    color: context.moreColors.mutedColor,
                                  ),
                                ),
                                const SizedBox(height: Spaces.small),
                                ...List.generate(multisigState.threshold, (
                                  index,
                                ) {
                                  return GenericFormBuilderDropdown(
                                    name: 'id_$index',
                                    items:
                                        multisigState.participants
                                            .map(
                                              (participant) => DropdownMenuItem(
                                                value: participant,
                                                child: Text(
                                                  participant.id.toString(),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    validator: FormBuilderValidators.required<
                                      MultisigParticipant
                                    >(errorText: loc.field_required_error),
                                    onChanged: (value) {
                                      // workaround to reset the error message when the user modifies the field
                                      final hasError =
                                          _signaturesFormKey
                                              .currentState
                                              ?.fields['id_$index']
                                              ?.hasError;
                                      if (hasError ?? false) {
                                        _signaturesFormKey
                                            .currentState
                                            ?.fields['id_$index']
                                            ?.reset();
                                      }
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: Spaces.medium),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Text(
                                  loc.signature,
                                  style: context.labelMedium?.copyWith(
                                    color: context.moreColors.mutedColor,
                                  ),
                                ),
                                const SizedBox(height: Spaces.small),
                                ...List.generate(multisigState.threshold, (
                                  index,
                                ) {
                                  return FormBuilderTextField(
                                    name: 'signature_$index',
                                    autocorrect: false,
                                    keyboardType: TextInputType.text,
                                    decoration: context.textInputDecoration,
                                    validator: FormBuilderValidators.required(
                                      errorText: loc.field_required_error,
                                    ),
                                    onChanged: (value) {
                                      // workaround to reset the error message when the user modifies the field
                                      final hasError =
                                          _signaturesFormKey
                                              .currentState
                                              ?.fields['signature_$index']
                                              ?.hasError;
                                      if (hasError ?? false) {
                                        _signaturesFormKey
                                            .currentState
                                            ?.fields['signature_$index']
                                            ?.reset();
                                      }
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : widget.reviewContent,
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animFast),
          child:
              transactionReview.hasSummary
                  ? transactionReview.isBroadcast
                      ? TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: Text(loc.ok_button),
                      )
                      : TextButton.icon(
                        onPressed:
                            transactionReview.isConfirmed
                                ? () => startWithBiometricAuth(
                                  ref,
                                  callback: _broadcastTransfer,
                                  reason: loc.please_authenticate_tx,
                                )
                                : null,
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(loc.broadcast),
                      )
                  : TextButton.icon(
                    onPressed: _processSignatures,
                    label: Text(loc.next),
                    icon: Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
        ),
      ],
    );
  }

  Future<void> _processSignatures() async {
    context.loaderOverlay.show();

    if (_signaturesFormKey.currentState?.saveAndValidate() ?? false) {
      List<SignatureMultisig> signatures = List.generate(
        ref.read(walletStateProvider).multisigState.threshold,
        (index) {
          final multisigParticipant =
              _signaturesFormKey.currentState?.fields['id_$index']?.value
                  as MultisigParticipant;
          final signature =
              _signaturesFormKey.currentState?.fields['signature_$index']?.value
                  as String;
          return SignatureMultisig(
            id: multisigParticipant.id,
            signature: signature,
          );
        },
      );

      final tx = await ref
          .read(walletStateProvider.notifier)
          .finalizeDeleteMultisig(signatures: signatures);

      if (tx != null) {
        if (tx.isTransfer) {
          ref.read(transactionReviewProvider.notifier).setTransferSummary(tx);
        } else if (tx.isMultiSig) {
          ref.read(transactionReviewProvider.notifier).setMultisigSummary(tx);
        } else if (tx.isBurn) {
          ref.read(transactionReviewProvider.notifier).setBurnSummary(tx);
        } else {
          talker.error('Unknown transaction type');
        }
      }
    }

    if (mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  Future<void> _broadcastTransfer(WidgetRef ref) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      ref.context.loaderOverlay.show();

      final transactionReview = ref.read(transactionReviewProvider);

      await ref
          .read(walletStateProvider.notifier)
          .broadcastTx(hash: transactionReview.finalHash!);

      ref.read(transactionReviewProvider.notifier).broadcast();

      if (transactionReview.summary!.isMultiSig) {
        ref.read(multisigPendingStateProvider.notifier).pendingState();
      }

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
