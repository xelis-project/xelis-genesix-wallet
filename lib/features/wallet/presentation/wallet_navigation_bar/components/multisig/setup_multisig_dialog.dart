import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

class SetupMultisigDialog extends ConsumerStatefulWidget {
  const SetupMultisigDialog({super.key});

  @override
  ConsumerState createState() => _SetupMultisigDialogState();
}

class _SetupMultisigDialogState extends ConsumerState<SetupMultisigDialog> {
  final _multisigFormKey = GlobalKey<FormState>();
  final TextEditingController _thresholdController = TextEditingController();
  final List<TextEditingController> _participantControllers = [];
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _participantsScrollController = ScrollController();

  bool _isBroadcast = false;
  bool _isConfirmed = false;
  bool _isPreparing = false;
  bool _isBroadcasting = false;
  TransactionSummary? _transactionSummary;

  @override
  void initState() {
    super.initState();
    _participantControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    for (final controller in _participantControllers) {
      controller.dispose();
    }
    _mainScrollController.dispose();
    _participantsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    bool transactionReadyToBroadcast = _transactionSummary != null;
    return AppDialog(
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
                    key: ValueKey(_transactionSummary),
                    _transactionSummary != null
                        ? loc.review
                        : loc.multisig_setup_title,
                    style: context.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    maxLines: 1,
                  ),
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
                  icon: const Icon(FLucideIcons.x),
                ),
              ),
          ],
        ),
      ),
      body: Container(
        constraints: BoxConstraints(maxWidth: 600),
        width: double.maxFinite,
        child: ScrollConfiguration(
          behavior: context.scrollBehavior.copyWith(scrollbars: false),
          child: ListView(
            controller: _mainScrollController,
            shrinkWrap: true,
            children: [
              if (!transactionReadyToBroadcast) ...[
                FAlert(
                  title: Text(loc.warning),
                  subtitle: Text(
                    '${loc.multisig_setup_message_1}\n'
                    '${loc.multisig_setup_message_2}\n'
                    '${loc.multisig_setup_message_3}',
                  ),
                ),
                const SizedBox(height: Spaces.large),
              ],
              !transactionReadyToBroadcast
                  ? Form(
                      key: _multisigFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.threshold,
                            style: context.labelLarge?.copyWith(
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: Spaces.extraSmall),
                          FTextFormField(
                            control: .managed(controller: _thresholdController),
                            autocorrect: false,
                            keyboardType: TextInputType.number,
                            label: Text(loc.threshold_formfield_label_text),
                            validator: (value) => _validateThreshold(value),
                          ),
                          const SizedBox(height: Spaces.large),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.participants,
                                style: context.labelLarge?.copyWith(
                                  color: context.theme.colors.mutedForeground,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _addParticipant,
                                    icon: Icon(FLucideIcons.plus, size: 18),
                                  ),
                                  IconButton(
                                    onPressed: _removeParticipant,
                                    icon: Icon(FLucideIcons.minus, size: 18),
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
                              itemCount: _participantControllers.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Spaces.small,
                                  ),
                                  child: AppCard(
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
                                                      color: context
                                                          .theme
                                                          .colors
                                                          .mutedForeground,
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
                                          child: _buildParticipantField(index),
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
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: Spaces.extraSmall),
                          SelectableText(_transactionSummary!.hash),
                          const SizedBox(height: Spaces.small),
                          Text(
                            loc.fee,
                            style: context.bodyLarge!.copyWith(
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: Spaces.extraSmall),
                          SelectableText(
                            formatXelis(_transactionSummary!.fee, network),
                          ),
                          const SizedBox(height: Spaces.small),
                          Text(
                            loc.threshold,
                            style: context.bodyLarge!.copyWith(
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: Spaces.extraSmall),
                          SelectableText(
                            (_transactionSummary!.transactionType
                                    as sdk.MultisigBuilder)
                                .threshold
                                .toString(),
                          ),
                          const SizedBox(height: Spaces.small),
                          Text(
                            loc.participants,
                            style: context.bodyLarge!.copyWith(
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: Spaces.extraSmall),
                          Builder(
                            builder: (BuildContext context) {
                              final participants =
                                  (_transactionSummary!.transactionType
                                          as sdk.MultisigBuilder)
                                      .participants;
                              return Column(
                                children: participants.map((participant) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Spaces.small,
                                    ),
                                    child: AppCard(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: Spaces.extraSmall,
                                                ),
                                                child: Text(
                                                  loc.id,
                                                  style: context.labelMedium
                                                      ?.copyWith(
                                                        color: context
                                                            .theme
                                                            .colors
                                                            .mutedForeground,
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
                                          const SizedBox(width: Spaces.medium),
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
                                                          color: context
                                                              .theme
                                                              .colors
                                                              .mutedForeground,
                                                        ),
                                                  ),
                                                ),
                                                AddressWidget(
                                                  participant.toString(),
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
                            child: _isBroadcast
                                ? SizedBox.shrink()
                                : FCheckbox(
                                    value: _isConfirmed,
                                    label: Text(
                                      loc.multisig_setup_confirmation_message,
                                      style: context.bodyMedium,
                                    ),
                                    onChange: (value) {
                                      setState(() {
                                        _isConfirmed = value;
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
                      onPressed: _isConfirmed && !_isBroadcasting
                          ? () => startWithBiometricAuth(
                              ref,
                              callback: _broadcastTransfer,
                              reason: loc.please_authenticate_tx,
                            )
                          : null,
                      icon: _isBroadcasting
                          ? const FCircularProgress.loader()
                          : const Icon(FLucideIcons.send, size: 18),
                      label: Text(loc.broadcast),
                    )
            : TextButton.icon(
                onPressed: _isPreparing ? null : _confirmMultisigSetup,
                label: Text(loc.next),
                icon: _isPreparing
                    ? const FCircularProgress.loader()
                    : Icon(FLucideIcons.arrowRight, size: 18),
              ),
      ],
    );
  }

  String? _validateThreshold(String? value) {
    final loc = ref.read(appLocalizationsProvider);
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return loc.field_required_error;
    }
    final threshold = int.tryParse(raw);
    if (threshold == null) {
      return loc.must_be_numeric_error;
    }
    if (threshold < 1 ||
        threshold > 255 ||
        threshold > _participantControllers.length) {
      return loc.threshold_formfield_error;
    }
    return null;
  }

  Widget _buildParticipantField(int index) {
    final loc = ref.read(appLocalizationsProvider);
    return FTextFormField(
      key: ValueKey(_participantControllers[index]),
      control: .managed(controller: _participantControllers[index]),
      autocorrect: false,
      keyboardType: TextInputType.text,
      label: Text(loc.wallet_address_capitalize.toLowerCase()),
      clearable: (value) => value.text.isNotEmpty,
      validator: (value) => _validateParticipant(value, index),
    );
  }

  String? _validateParticipant(String? value, int index) {
    final loc = ref.read(appLocalizationsProvider);
    final address = value?.trim() ?? '';
    if (address.isEmpty) {
      return loc.field_required_error;
    }
    if (!ref.read(walletCommandsProvider).isAddressValidForMultisig(address)) {
      return loc.multisig_address_validation_error;
    }
    final duplicated = _participantControllers.indexed.any(
      (entry) => entry.$1 != index && entry.$2.text.trim() == address,
    );
    if (duplicated) {
      return loc.multisig_participant_duplicated;
    }
    return null;
  }

  void _addParticipant() {
    if (_participantControllers.length < 255) {
      setState(() {
        _participantControllers.add(TextEditingController());
      });

      // scroll to the bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_participantControllers.length > 1) {
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
    if (_participantControllers.length > 1) {
      setState(() {
        _participantControllers.removeLast().dispose();
      });
    }
  }

  Future<void> _confirmMultisigSetup() async {
    if (_isPreparing) return;

    if (_multisigFormKey.currentState?.validate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final threshold = int.parse(_thresholdController.text.trim());
      final participants = _participantControllers
          .map((controller) => controller.text.trim())
          .toList();

      setState(() => _isPreparing = true);

      final TransactionSummary? transactionSummary;
      try {
        transactionSummary = await ref
            .read(walletCommandsProvider)
            .setupMultisig(participants: participants, threshold: threshold);
      } finally {
        if (mounted) {
          setState(() => _isPreparing = false);
        }
      }

      if (!mounted) return;

      if (transactionSummary != null) {
        if (transactionSummary.isMultiSig) {
          setState(() {
            _transactionSummary = transactionSummary;
          });
        } else {
          ref.read(toastProvider.notifier).showError(description: loc.oups);
        }
      }
    }
  }

  Future<void> _broadcastTransfer(WidgetRef ref) async {
    if (_isBroadcasting) return;

    final loc = ref.read(appLocalizationsProvider);
    setState(() => _isBroadcasting = true);

    try {
      final broadcasted = await ref
          .read(walletCommandsProvider)
          .broadcastTx(hash: _transactionSummary!.hash);
      if (!broadcasted) {
        return;
      }

      setState(() {
        _isBroadcast = true;
      });

      ref.read(multisigPendingStateProvider.notifier).pendingState();

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
    } finally {
      if (mounted) {
        setState(() => _isBroadcasting = false);
      }
    }
  }
}
