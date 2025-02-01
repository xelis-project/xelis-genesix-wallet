import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_participant.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/rust_bridge/api/dtos.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class DeleteMultisigDialog extends ConsumerStatefulWidget {
  const DeleteMultisigDialog(this.transactionToSign, {super.key});

  final String transactionToSign;

  @override
  ConsumerState createState() => _DeleteMultisigDialogState();
}

class _DeleteMultisigDialogState extends ConsumerState<DeleteMultisigDialog> {
  final _signaturesFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_signaturesFormKey');
  bool _isBroadcast = false;

  TransactionSummary? _transactionSummary;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState =
        ref.watch(walletStateProvider.select((value) => value.multisigState));
    return GenericDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: Spaces.medium, top: Spaces.large),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animFast),
              child: Text(
                key: ValueKey(_transactionSummary),
                _transactionSummary != null ? loc.review : 'Multisig',
                style: context.headlineSmall,
              ),
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
        constraints: BoxConstraints(maxWidth: 600),
        child: _transactionSummary == null
            ? Column(
                key: ValueKey(_transactionSummary),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaction to sign',
                          style: context.titleMedium
                              ?.copyWith(color: context.moreColors.mutedColor)),
                      IconButton(
                        onPressed: () => copyToClipboard(
                            widget.transactionToSign, ref, loc.copied),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy hash transaction',
                      ),
                    ],
                  ),
                  const SizedBox(height: Spaces.small),
                  SelectableText(widget.transactionToSign),
                  const SizedBox(height: Spaces.small),
                  Divider(),
                  const SizedBox(height: Spaces.small),
                  Text(
                      'As Multisig is activated, you need to provide the required signatures to continue.',
                      style: context.labelMedium
                          ?.copyWith(color: context.moreColors.mutedColor)),
                  const SizedBox(height: Spaces.large),
                  FormBuilder(
                    key: _signaturesFormKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Participant ID',
                                  style: context.labelMedium?.copyWith(
                                      color: context.moreColors.mutedColor)),
                              const SizedBox(height: Spaces.small),
                              ...List.generate(multisigState.threshold,
                                  (index) {
                                return FormBuilderDropdown(
                                  name: 'id_$index',
                                  enableFeedback: true,
                                  dropdownColor: context.colors.surface
                                      .withValues(alpha: 0.9),
                                  focusColor: context.colors.surface
                                      .withValues(alpha: 0.9),
                                  items: multisigState.participants
                                      .map(
                                        (participant) => DropdownMenuItem(
                                          value: participant,
                                          child:
                                              Text(participant.id.toString()),
                                        ),
                                      )
                                      .toList(),
                                  validator: FormBuilderValidators.required<
                                          MultisigParticipant>(
                                      errorText: loc.field_required_error),
                                  onChanged: (value) {
                                    // workaround to reset the error message when the user modifies the field
                                    final hasError = _signaturesFormKey
                                        .currentState
                                        ?.fields['id_$index']
                                        ?.hasError;
                                    if (hasError ?? false) {
                                      _signaturesFormKey
                                          .currentState?.fields['id_$index']
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
                              Text('Signature',
                                  style: context.labelMedium?.copyWith(
                                      color: context.moreColors.mutedColor)),
                              const SizedBox(height: Spaces.small),
                              ...List.generate(multisigState.threshold,
                                  (index) {
                                return FormBuilderTextField(
                                  name: 'signature_$index',
                                  autocorrect: false,
                                  keyboardType: TextInputType.text,
                                  decoration: context.textInputDecoration,
                                  validator: FormBuilderValidators.required(
                                      errorText: loc.field_required_error),
                                  onChanged: (value) {
                                    // workaround to reset the error message when the user modifies the field
                                    final hasError = _signaturesFormKey
                                        .currentState
                                        ?.fields['signature_$index']
                                        ?.hasError;
                                    if (hasError ?? false) {
                                      _signaturesFormKey.currentState
                                          ?.fields['signature_$index']
                                          ?.reset();
                                    }
                                  },
                                );
                              }),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.hash,
                      style: context.bodyLarge!
                          .copyWith(color: context.moreColors.mutedColor),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(_transactionSummary!.hash),
                    const SizedBox(height: Spaces.small),
                    Text(
                      loc.fee,
                      style: context.bodyLarge!
                          .copyWith(color: context.moreColors.mutedColor),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(formatXelis(_transactionSummary!.fee)),
                    const SizedBox(height: Spaces.small),
                    Text(
                      'Transaction type',
                      style: context.bodyLarge!
                          .copyWith(color: context.moreColors.mutedColor),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText('Delete Multisig'),
                  ],
                ),
              ),
      ),
      actions: [
        _transactionSummary != null
            ? _isBroadcast
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
                      reason:
                          'Please authenticate to broadcast the transaction',
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(loc.broadcast),
                  )
            : TextButton.icon(
                onPressed: _processSignatures,
                label: Text(
                  loc.next,
                ),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
              ),
      ],
    );
  }

  Future<void> _processSignatures() async {
    context.loaderOverlay.show();

    if (_signaturesFormKey.currentState?.saveAndValidate() ?? false) {
      List<SignatureMultisig> signatures = List.generate(
          ref.read(walletStateProvider).multisigState.threshold, (index) {
        final multisigParticipant = _signaturesFormKey
            .currentState?.fields['id_$index']?.value as MultisigParticipant;
        final signature = _signaturesFormKey
            .currentState?.fields['signature_$index']?.value as String;
        return SignatureMultisig(
            id: multisigParticipant.id, signature: signature);
      });

      final tx = await ref
          .read(walletStateProvider.notifier)
          .finalizeDeleteMultisig(signatures: signatures);

      if (tx != null) {
        setState(() {
          _transactionSummary = tx;
        });
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

      await ref
          .read(walletStateProvider.notifier)
          .broadcastTx(hash: _transactionSummary!.hash);

      setState(() {
        _isBroadcast = true;
      });

      ref.read(multisigPendingStateProvider.notifier).pendingState();

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
