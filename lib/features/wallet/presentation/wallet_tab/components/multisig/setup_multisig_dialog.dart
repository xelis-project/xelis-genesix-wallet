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
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/warning_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class SetupMultisigDialog extends ConsumerStatefulWidget {
  const SetupMultisigDialog({super.key});

  @override
  ConsumerState createState() => _SetupMultisigDialogState();
}

class _SetupMultisigDialogState extends ConsumerState<SetupMultisigDialog> {
  final _multisigFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_multisigFormKey',
  );
  final List<FormBuilderTextField> _participantFormFields = [];
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _participantsScrollController = ScrollController();

  bool _isBroadcast = false;
  bool _isConfirmed = false;
  TransactionSummary? _transactionSummary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_participantFormFields.isEmpty) _addParticipant();
  }

  @override
  void dispose() {
    _participantsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    bool transactionReadyToBroadcast = _transactionSummary != null;
    return GenericDialog(
      scrollable: false,
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
                key: ValueKey(_transactionSummary),
                _transactionSummary != null
                    ? loc.review
                    : loc.multisig_setup_title,
                style: context.headlineSmall,
              ),
            ),
          ),
          if (!_isBroadcast)
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
        width: double.maxFinite,
        child: ScrollConfiguration(
          behavior: context.scrollBehavior.copyWith(scrollbars: false),
          child: ListView(
            controller: _mainScrollController,
            shrinkWrap: true,
            children: [
              if (!transactionReadyToBroadcast) ...[
                WarningWidget([
                  '${loc.multisig_setup_message_1}\n',
                  '${loc.multisig_setup_message_2}\n',
                  (loc.multisig_setup_message_3),
                ]),
                const SizedBox(height: Spaces.large),
              ],
              !transactionReadyToBroadcast
                  ? FormBuilder(
                    key: _multisigFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.threshold,
                          style: context.labelLarge?.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        FormBuilderTextField(
                          name: 'threshold',
                          style: context.bodyMedium,
                          autocorrect: false,
                          keyboardType: TextInputType.number,
                          decoration: context.textInputDecoration.copyWith(
                            labelText: loc.threshold_formfield_label_text,
                            labelStyle: context.labelMedium!.copyWith(
                              color: context.moreColors.mutedColor,
                            ),
                          ),
                          onChanged: (value) {
                            // workaround to reset the error message when the user modifies the field
                            final hasError =
                                _multisigFormKey
                                    .currentState
                                    ?.fields['threshold']
                                    ?.hasError;
                            if (hasError ?? false) {
                              _multisigFormKey.currentState?.fields['threshold']
                                  ?.reset();
                            }
                          },
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                              errorText: loc.field_required_error,
                            ),
                            FormBuilderValidators.numeric(
                              errorText: loc.must_be_numeric_error,
                            ),
                            FormBuilderValidators.min(1),
                            FormBuilderValidators.max(255),
                            (value) {
                              final threshold = int.tryParse(value ?? '');
                              if (threshold != null &&
                                  threshold > _participantFormFields.length) {
                                return loc.threshold_formfield_error;
                              }
                              return null;
                            },
                          ]),
                        ),
                        const SizedBox(height: Spaces.large),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.participants,
                              style: context.labelLarge?.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _addParticipant,
                                  icon: Icon(Icons.add, size: 18),
                                ),
                                IconButton(
                                  onPressed: _removeParticipant,
                                  icon: Icon(Icons.remove, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            shrinkWrap: true,
                            controller: _participantsScrollController,
                            itemCount: _participantFormFields.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    Spaces.medium,
                                    Spaces.medium,
                                    Spaces.medium,
                                    Spaces.medium,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: Spaces.extraSmall,
                                            ),
                                            child: Text(
                                              loc.id,
                                              style: context.labelLarge
                                                  ?.copyWith(
                                                    color:
                                                        context
                                                            .moreColors
                                                            .mutedColor,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            index.toString(),
                                            style: context.bodyLarge,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: Spaces.large),
                                      Expanded(
                                        child: _participantFormFields[index],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                  : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.hash,
                          style: context.bodyLarge!.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        SelectableText(_transactionSummary!.hash),
                        const SizedBox(height: Spaces.small),
                        Text(
                          loc.fee,
                          style: context.bodyLarge!.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        SelectableText(formatXelis(_transactionSummary!.fee)),
                        const SizedBox(height: Spaces.small),
                        Text(
                          loc.threshold,
                          style: context.bodyLarge!.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        SelectableText(
                          _transactionSummary!
                              .transactionSummaryType
                              .multisig!
                              .threshold
                              .toString(),
                        ),
                        const SizedBox(height: Spaces.small),
                        Text(
                          loc.participants,
                          style: context.bodyLarge!.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        Builder(
                          builder: (BuildContext context) {
                            final participants =
                                _transactionSummary!
                                    .transactionSummaryType
                                    .multisig!
                                    .participants;
                            return Column(
                              children:
                                  participants.map((participant) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          Spaces.medium,
                                          Spaces.small,
                                          Spaces.medium,
                                          Spaces.small,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom:
                                                            Spaces.extraSmall,
                                                      ),
                                                  child: Text(
                                                    loc.id,
                                                    style: context.labelMedium
                                                        ?.copyWith(
                                                          color:
                                                              context
                                                                  .moreColors
                                                                  .mutedColor,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  participants
                                                      .indexOf(participant)
                                                      .toString(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              width: Spaces.medium,
                                            ),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom:
                                                              Spaces.extraSmall,
                                                        ),
                                                    child: Text(
                                                      loc.address,
                                                      style: context.labelMedium
                                                          ?.copyWith(
                                                            color:
                                                                context
                                                                    .moreColors
                                                                    .mutedColor,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    participant.toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: Spaces.large),
                        AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: AppDurations.animFast,
                          ),
                          child:
                              _isBroadcast
                                  ? SizedBox.shrink()
                                  : FormBuilderCheckbox(
                                    name: 'confirm',
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.only(
                                        top: Spaces.small,
                                      ),
                                      isDense: true,
                                      fillColor: Colors.transparent,
                                    ),
                                    title: Text(
                                      loc.multisig_setup_confirmation_message,
                                      style: context.bodyMedium,
                                    ),
                                    validator: FormBuilderValidators.required(
                                      errorText: loc.field_required_error,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _isConfirmed = value ?? false;
                                      });
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
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
                  onPressed:
                      _isConfirmed
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
              onPressed: _confirmMultisigSetup,
              label: Text(loc.next),
              icon: Icon(Icons.arrow_forward_rounded, size: 18),
            ),
      ],
    );
  }

  void _addParticipant() {
    if (_participantFormFields.length < 255) {
      final loc = ref.read(appLocalizationsProvider);
      int index = _participantFormFields.length;
      String participantFieldId = 'participant_$index';
      setState(() {
        _participantFormFields.add(
          FormBuilderTextField(
            name: participantFieldId,
            style: context.bodyMedium,
            autocorrect: false,
            keyboardType: TextInputType.text,
            decoration: context.textInputDecoration.copyWith(
              suffixIcon: IconButton(
                hoverColor: Colors.transparent,
                onPressed:
                    () =>
                        _multisigFormKey
                            .currentState
                            ?.fields[participantFieldId]
                            ?.reset(),
                icon: Icon(
                  Icons.clear,
                  size: 18,
                  color: context.moreColors.mutedColor,
                ),
              ),
            ),
            onChanged: (value) {
              // workaround to reset the error message when the user modifies the field
              final hasError =
                  _multisigFormKey
                      .currentState
                      ?.fields[participantFieldId]
                      ?.hasError;
              if (hasError ?? false) {
                _multisigFormKey.currentState?.fields[participantFieldId]
                    ?.reset();
              }
            },
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: loc.field_required_error,
              ),
              // check if the address is valid for multisig
              (value) {
                if (value != null &&
                    !ref
                        .read(walletStateProvider.notifier)
                        .isAddressValidForMultisig(value)) {
                  return loc.multisig_address_validation_error;
                }
                return null;
              },
              // check if the address is already a participant
              (value) {
                if (value != null) {
                  final List<String>? participants =
                      _multisigFormKey.currentState?.fields.keys
                          .where(
                            (element) =>
                                element.startsWith('participant_') &&
                                element != participantFieldId,
                          )
                          .map(
                            (e) =>
                                _multisigFormKey.currentState?.fields[e]?.value
                                    as String?,
                          )
                          .where((element) => element != null)
                          .cast<String>()
                          .toList();
                  if (participants?.contains(value) ?? false) {
                    return loc.multisig_participant_duplicated;
                  }
                }
                return null;
              },
            ]),
          ),
        );
      });

      // scroll to the bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_participantFormFields.length > 1) {
          _mainScrollController.animateTo(
            _mainScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: AppDurations.animFast),
            curve: Curves.easeOut,
          );
        }
        _participantsScrollController.animateTo(
          _participantsScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: AppDurations.animFast),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _removeParticipant() {
    if (_participantFormFields.length > 1) {
      setState(() {
        _participantFormFields.removeLast();
      });
    }
  }

  Future<void> _confirmMultisigSetup() async {
    if (_multisigFormKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final threshold = int.parse(
        (_multisigFormKey.currentState?.value['threshold'] as String).trim(),
      );
      final participants =
          _multisigFormKey.currentState?.fields.keys
                  .where((element) => element.startsWith('participant_'))
                  .map(
                    (e) =>
                        _multisigFormKey.currentState?.fields[e]?.value
                            as String,
                  )
                  .map((e) => e.trim())
                  .toList()
              as List<String>;

      context.loaderOverlay.show();

      final transactionSummary = await ref
          .read(walletStateProvider.notifier)
          .setupMultisig(participants: participants, threshold: threshold);

      if (transactionSummary != null) {
        if (transactionSummary.isMultiSig) {
          setState(() {
            _transactionSummary = transactionSummary;
          });
        } else {
          ref.read(snackBarMessengerProvider.notifier).showError(loc.oups);
        }
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
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
