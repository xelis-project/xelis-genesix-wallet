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
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/burn/burn_review_content.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/multisig/delete_multisig_review_content.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transfer/transfer_review_content.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration_old.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog_old.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown_old.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class TransactionDialog extends ConsumerStatefulWidget {
  const TransactionDialog({super.key});

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

    final signaturePending = transactionReview is SignaturePending;

    var reviewContent = switch (transactionReview) {
      DeleteMultisigTransaction() => DeleteMultisigReviewContent(
        transactionReview,
      ),
      BurnTransaction() => BurnReviewContent(transactionReview),
      SingleTransferTransaction() => TransferReviewContentWidget(
        transactionReview,
      ),
      _ => const SizedBox.shrink(),
    };

    return GenericDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: AppDurations.animFast),
                  child: Text(
                    key: ValueKey(signaturePending),
                    signaturePending ? loc.multisig : loc.review,
                    style: context.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            if (!transactionReview.isBroadcasted)
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
      ),
      content: Container(
        constraints: BoxConstraints(maxWidth: 600),
        child: signaturePending
            ? Column(
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
                        onPressed: () => copyToClipboard(
                          (transactionReview).hashToSign,
                          ref,
                          loc.copied,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: loc.copy_hash_transaction,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spaces.small),
                  SelectableText(transactionReview.hashToSign),
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
                                  items: multisigState.participants
                                      .map(
                                        (participant) => DropdownMenuItem(
                                          value: participant,
                                          child: Text(
                                            participant.id.toString(),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  validator:
                                      FormBuilderValidators.required<
                                        MultisigParticipant
                                      >(errorText: loc.field_required_error),
                                  onChanged: (value) {
                                    // workaround to reset the error message when the user modifies the field
                                    final hasError = _signaturesFormKey
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
                                    final hasError = _signaturesFormKey
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
            : reviewContent,
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: signaturePending
              ? TextButton.icon(
                  onPressed: _processSignatures,
                  label: Text(loc.next),
                  icon: Icon(Icons.arrow_forward_rounded, size: 18),
                )
              : transactionReview.isBroadcasted
              ? TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: Text(loc.ok_button),
                )
              : TextButton.icon(
                  onPressed: transactionReview.isConfirmed
                      ? () => startWithBiometricAuth(
                          ref,
                          callback: _broadcastTransfer,
                          reason: loc.please_authenticate_tx,
                        )
                      : null,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(loc.broadcast),
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
          .finalizeMultisigTransaction(signatures: signatures);

      if (tx != null) {
        if (tx.isTransfer) {
          ref
              .read(transactionReviewProvider.notifier)
              .setSingleTransferTransaction(tx);
        } else if (tx.isMultiSig) {
          ref
              .read(transactionReviewProvider.notifier)
              .setDeleteMultisigTransaction(tx);
        } else if (tx.isBurn) {
          ref.read(transactionReviewProvider.notifier).setBurnTransaction(tx);
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

      switch (transactionReview) {
        case DeleteMultisigTransaction(:final txHash) ||
            SingleTransferTransaction(:final txHash) ||
            BurnTransaction(:final txHash):
          await ref
              .read(walletStateProvider.notifier)
              .broadcastTx(hash: txHash);
        default:
          throw Exception('TransactionReviewState not supported');
      }

      ref.read(transactionReviewProvider.notifier).broadcast();

      if (transactionReview is DeleteMultisigTransaction) {
        ref.read(multisigPendingStateProvider.notifier).pendingState();
      }

      ref
          .read(toastProvider.notifier)
          .showEvent(description: loc.transaction_broadcast_message);
    } on AnyhowException catch (e) {
      talker.error('Cannot broadcast transaction: $e');
      final xelisMessage = (e).message.split("\n")[0];
      ref.read(toastProvider.notifier).showError(description: xelisMessage);
    } catch (e) {
      talker.error('Cannot broadcast transaction: $e');
      ref.read(toastProvider.notifier).showError(description: e.toString());
    }

    if (ref.context.mounted) {
      ref.context.loaderOverlay.hide();
    }
  }
}
