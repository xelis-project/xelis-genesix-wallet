import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:go_router/go_router.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_participant.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/burn/burn_review_content.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/multisig/delete_multisig_review_content.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transfer/transfer_review_content.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

class TransactionReviewDialogNew extends ConsumerStatefulWidget {
  const TransactionReviewDialogNew(this.animation, {super.key});

  final Animation<double> animation;

  @override
  ConsumerState<TransactionReviewDialogNew> createState() =>
      _TransactionReviewDialogNewState();
}

class _TransactionReviewDialogNewState
    extends ConsumerState<TransactionReviewDialogNew> {
  final _signaturesFormKey = GlobalKey<FormState>();
  final List<FSelectController<MultisigParticipant>> _participantControllers =
      [];
  final List<TextEditingController> _signatureControllers = [];
  var _isProcessingSignatures = false;
  var _isBroadcasting = false;

  @override
  void dispose() {
    for (final controller in _participantControllers) {
      controller.dispose();
    }
    for (final controller in _signatureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState = ref.watch(
      walletRuntimeProvider.select((value) => value.multisigState),
    );
    final transactionReview = ref.watch(transactionReviewProvider);

    final signaturePending = transactionReview is SignaturePending;

    final Widget reviewContent = switch (transactionReview) {
      DeleteMultisigTransaction() => DeleteMultisigReviewContent(
        transactionReview,
      ),
      BurnTransaction() => BurnReviewContent(transactionReview),
      SingleTransferTransaction() => TransferReviewContentWidget(
        transactionReview,
      ),
      _ => const SizedBox.shrink(),
    };

    return AppDialog(
      clipBehavior: Clip.antiAlias,
      animation: widget.animation,
      constraints: const BoxConstraints(maxWidth: 600),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(Spaces.extraSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: AppDurations.animFast,
                    ),
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
                if (!transactionReview.isBroadcasted)
                  FButton.icon(
                    variant: .ghost,
                    onPress: () => context.pop(),
                    child: const Icon(FLucideIcons.x, size: 22),
                  ),
              ],
            ),
          ),

          const SizedBox(height: Spaces.extraSmall),

          // Body
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: signaturePending
                ? _buildSignaturePendingContent(
                    context,
                    multisigState,
                    transactionReview,
                  )
                : reviewContent,
          ),
        ],
      ),

      // Actions
      actions: [
        SizedBox(
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animFast),
              child: _buildRightActionButton(
                context,
                transactionReview,
                signaturePending,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// --- Signature-pending content (multisig) ---

  Widget _buildSignaturePendingContent(
    BuildContext context,
    MultisigState multisigState,
    SignaturePending transactionReview,
  ) {
    final loc = ref.watch(appLocalizationsProvider);
    _ensureSignatureInputs(multisigState.threshold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hash to sign
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.transaction_hash_to_sign,
              style: context.titleMedium?.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            IconButton(
              onPressed: () => copyToClipboard(
                transactionReview.hashToSign,
                ref,
                loc.copied,
              ),
              icon: const Icon(FLucideIcons.copy, size: 18),
              tooltip: loc.copy_hash_transaction,
            ),
          ],
        ),
        const SizedBox(height: Spaces.small),
        SelectableText(transactionReview.hashToSign),
        const SizedBox(height: Spaces.small),
        const Divider(),
        const SizedBox(height: Spaces.small),
        Text(
          loc.multisig_barrier_message,
          style: context.labelMedium?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.large),

        // Form
        Form(
          key: _signaturesFormKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant IDs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.participant_id,
                      style: context.labelMedium?.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: Spaces.small),
                    ...List.generate(multisigState.threshold, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spaces.small),
                        child: FSelect<MultisigParticipant>(
                          control: .managed(
                            controller: _participantControllers[index],
                          ),
                          items: multisigState.participants
                              .fold<Map<String, MultisigParticipant>>(
                                {},
                                (items, participant) => items
                                  ..[participant.id.toString()] = participant,
                              ),
                          validator: (value) =>
                              value == null ? loc.field_required_error : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(width: Spaces.medium),

              // Signatures
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.signature,
                      style: context.labelMedium?.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: Spaces.small),
                    ...List.generate(multisigState.threshold, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spaces.small),
                        child: FTextFormField(
                          control: .managed(
                            controller: _signatureControllers[index],
                          ),
                          autocorrect: false,
                          keyboardType: TextInputType.text,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? loc.field_required_error
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// --- Right side button (Next / Broadcast / OK) ---

  Widget _buildRightActionButton(
    BuildContext context,
    TransactionReviewState transactionReview,
    bool signaturePending,
  ) {
    final loc = ref.watch(appLocalizationsProvider);

    // 1) Multisig, signatures not finalized yet → Next
    if (signaturePending) {
      return AsyncFButton(
        key: const ValueKey('next'),
        isLoading: _isProcessingSignatures,
        onPress: _processSignatures,
        prefix: const Icon(FLucideIcons.arrowRight, size: 18),
        child: Text(loc.next),
      );
    }

    // 2) Already broadcast → OK
    if (transactionReview.isBroadcasted) {
      return FButton(
        key: const ValueKey('ok'),
        onPress: () => context.pop(),
        child: Text(loc.ok_button),
      );
    }

    // 3) Ready to broadcast → Broadcast (gated by confirmation)
    final canBroadcast = transactionReview.isConfirmed;

    return AsyncFButton(
      key: const ValueKey('broadcast'),
      isLoading: _isBroadcasting,
      onPress: canBroadcast
          ? () => startWithBiometricAuth(
              ref,
              callback: _broadcastTransfer,
              reason: loc.please_authenticate_tx,
            )
          : null,
      prefix: const Icon(FLucideIcons.send, size: 18),
      child: Text(loc.broadcast),
    );
  }

  /// --- Logic: finalize multisig signatures ---

  Future<void> _processSignatures() async {
    if (_isProcessingSignatures) return;

    if (!(_signaturesFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isProcessingSignatures = true);

    try {
      final threshold = ref.read(walletRuntimeProvider).multisigState.threshold;
      final signatures = List<SignatureMultisig>.generate(threshold, (index) {
        final multisigParticipant = _participantControllers[index].value!;
        final signature = _signatureControllers[index].text.trim();
        return SignatureMultisig(
          id: multisigParticipant.id,
          signature: signature,
        );
      });
      final tx = await ref
          .read(walletCommandsProvider)
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
    } finally {
      if (mounted) {
        setState(() => _isProcessingSignatures = false);
      }
    }
  }

  void _ensureSignatureInputs(int threshold) {
    while (_participantControllers.length < threshold) {
      _participantControllers.add(FSelectController<MultisigParticipant>());
      _signatureControllers.add(TextEditingController());
    }
    while (_participantControllers.length > threshold) {
      _participantControllers.removeLast().dispose();
      _signatureControllers.removeLast().dispose();
    }
  }

  /// --- Logic: broadcast any reviewed transaction ---

  Future<void> _broadcastTransfer(WidgetRef ref) async {
    if (_isBroadcasting) return;

    final loc = ref.read(appLocalizationsProvider);
    setState(() => _isBroadcasting = true);

    try {
      final transactionReview = ref.read(transactionReviewProvider);

      var broadcasted = false;
      switch (transactionReview) {
        case DeleteMultisigTransaction(:final txHash) ||
            SingleTransferTransaction(:final txHash) ||
            BurnTransaction(:final txHash):
          broadcasted = await ref
              .read(walletCommandsProvider)
              .broadcastTx(hash: txHash);
        default:
          throw Exception('TransactionReviewState not supported');
      }
      if (!broadcasted) {
        return;
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
    } finally {
      if (mounted) {
        setState(() => _isBroadcasting = false);
      }
    }
  }
}
