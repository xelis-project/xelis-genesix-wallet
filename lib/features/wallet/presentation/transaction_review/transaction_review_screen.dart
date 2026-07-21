import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:go_router/go_router.dart';

const _maxMultisigSignatureShareLength = 1024;

class TransactionReviewScreen extends ConsumerStatefulWidget {
  const TransactionReviewScreen({super.key});

  @override
  ConsumerState<TransactionReviewScreen> createState() =>
      _TransactionReviewScreenState();
}

class _TransactionReviewScreenState
    extends ConsumerState<TransactionReviewScreen> {
  bool _isFinalizing = false;
  bool _isBroadcasting = false;
  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final review = ref.watch(transactionReviewProvider);
    final busy = _isFinalizing || _isBroadcasting || _isClosing;
    final content = review.isBroadcasted
        ? _BroadcastComplete(onClose: _finish)
        : switch (review) {
            SignaturePending(:final request) => _SignatureCollectionStep(
              key: ValueKey('signature-${request.hash}'),
              request: request,
              isFinalizing: _isFinalizing,
              onFinalize: _finalize,
            ),
            SingleTransferTransaction() ||
            BurnTransaction() ||
            DeleteMultisigTransaction() => _BroadcastReviewStep(
              key: ValueKey('broadcast-${_transactionHash(review)}'),
              review: review,
              isBroadcasting: _isBroadcasting,
              onBroadcast: _broadcast,
            ),
            Initial() => _EmptyReview(onClose: _finish),
          };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _close(review);
      },
      child: FScaffold(
        header: FHeader.nested(
          title: Text(review is SignaturePending ? loc.multisig : loc.review),
          prefixes: [
            Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: FHeaderAction.back(
                onPress: busy ? null : () => _close(review),
              ),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spaces.medium),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: AppDurations.animFast),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finalize(List<String> signatureShares) async {
    if (_isFinalizing) return;
    final review = ref.read(transactionReviewProvider);
    if (review is! SignaturePending) return;
    final commands = ref.read(walletCommandsProvider);

    setState(() => _isFinalizing = true);
    try {
      final transaction = await commands.finalizeMultisigTransaction(
        txHash: review.request.hash,
        signatureShares: signatureShares,
      );
      if (transaction == null) return;
      if (!mounted) {
        await commands.cancelTransaction(hash: transaction.hash);
        return;
      }

      final notifier = ref.read(transactionReviewProvider.notifier);
      if (transaction.isTransfer) {
        notifier.setSingleTransferTransaction(transaction);
      } else if (transaction.isBurn) {
        await notifier.setBurnTransaction(transaction);
      } else if (transaction.isMultiSig) {
        notifier.setDeleteMultisigTransaction(transaction);
      } else {
        talker.error('Unsupported finalized multisig transaction type');
      }
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  Future<void> _broadcast(WidgetRef ref) async {
    if (_isBroadcasting) return;
    final review = ref.read(transactionReviewProvider);
    final hash = _transactionHash(review);
    if (hash == null) return;

    setState(() => _isBroadcasting = true);
    try {
      final broadcasted = await ref
          .read(walletCommandsProvider)
          .broadcastTx(hash: hash);
      if (!mounted || broadcasted == null) return;

      final loc = ref.read(appLocalizationsProvider);
      final toast = ref.read(toastProvider.notifier);
      switch (broadcasted) {
        case TransactionBroadcastResult.submitted:
          ref.read(transactionReviewProvider.notifier).broadcast();
          if (review is DeleteMultisigTransaction) {
            ref.read(multisigPendingStateProvider.notifier).pendingState();
          }
          toast.showEvent(description: loc.transaction_broadcast_message);
        case TransactionBroadcastResult.retryable:
          toast.showWarning(title: loc.transaction_broadcast_retry_message);
        case TransactionBroadcastResult.rejected:
        case TransactionBroadcastResult.localFailure:
          ref.read(transactionReviewProvider.notifier).reset();
          toast.showError(
            description: loc.transaction_broadcast_recreate_message,
          );
          context.pop();
        case TransactionBroadcastResult.submittedNeedsResync:
          ref.read(transactionReviewProvider.notifier).broadcast();
          if (review is DeleteMultisigTransaction) {
            ref.read(multisigPendingStateProvider.notifier).pendingState();
          }
          toast.showWarning(title: loc.transaction_broadcast_resync_message);
      }
    } finally {
      if (mounted) setState(() => _isBroadcasting = false);
    }
  }

  Future<void> _close(TransactionReviewState review) async {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    try {
      if (review case SignaturePending(:final request)) {
        final commands = ref.read(walletCommandsProvider);
        final pendingHash = commands.getPendingMultisigRequestHash();
        if (pendingHash != null && pendingHash != request.hash) {
          talker.error('Cannot close a mismatched multisig review');
          ref
              .read(toastProvider.notifier)
              .showError(description: ref.read(appLocalizationsProvider).oups);
          return;
        }
        if (pendingHash == request.hash) {
          final canceled = await commands.cancelPendingMultisigRequest(
            txHash: request.hash,
          );
          if (!canceled) return;
        }
      } else if (!review.isBroadcasted) {
        final hash = _transactionHash(review);
        if (hash != null) {
          await ref.read(walletCommandsProvider).cancelTransaction(hash: hash);
        }
      }
      if (!mounted) return;
      ref.read(transactionReviewProvider.notifier).reset();
      context.pop();
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  void _finish() {
    ref.read(transactionReviewProvider.notifier).reset();
    context.pop();
  }
}

class _SignatureCollectionStep extends ConsumerStatefulWidget {
  const _SignatureCollectionStep({
    required this.request,
    required this.isFinalizing,
    required this.onFinalize,
    super.key,
  });

  final MultisigSigningRequest request;
  final bool isFinalizing;
  final Future<void> Function(List<String>) onFinalize;

  @override
  ConsumerState<_SignatureCollectionStep> createState() =>
      _SignatureCollectionStepState();
}

class _SignatureCollectionStepState
    extends ConsumerState<_SignatureCollectionStep> {
  final _controller = TextEditingController();
  final List<MultisigSignatureShare> _verifiedShares = [];
  Timer? _inspectionTimer;
  _SignatureShareInputError? _inputError;
  bool _isInspecting = false;
  int _inspectionGeneration = 0;

  bool get _canFinalize =>
      !_isInspecting && _verifiedShares.length == widget.request.threshold;

  @override
  void didUpdateWidget(covariant _SignatureCollectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.hash != widget.request.hash ||
        oldWidget.request.threshold != widget.request.threshold) {
      _resetCollection();
    }
  }

  @override
  void dispose() {
    _inspectionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.small,
          children: [
            Text(
              loc.multisig_signing_request,
              style: context.theme.typography.display.xl,
            ),
            Text(
              loc.multisig_barrier_message,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        _SigningRequestCard(request: widget.request),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(Spaces.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.medium,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.signature_share,
                        style: context.theme.typography.display.lg,
                      ),
                    ),
                    FBadge(
                      variant: _canFinalize ? .primary : .secondary,
                      child: Text(
                        '${_verifiedShares.length}/${widget.request.threshold}',
                      ),
                    ),
                  ],
                ),
                for (final share in _verifiedShares)
                  _VerifiedParticipant(
                    signerId: share.signerId,
                    participant: _participantFor(share),
                    onRemove: widget.isFinalizing
                        ? null
                        : () => _removeShare(share),
                  ),
                if (_canFinalize)
                  const _SignatureCollectionComplete()
                else
                  _SignatureShareInput(
                    controller: _controller,
                    error: _localizedInputError(loc),
                    isInspecting: _isInspecting,
                    onChanged: _queueInspection,
                    onPaste: _pasteShare,
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AsyncFButton(
            isLoading: widget.isFinalizing,
            onPress: !_canFinalize || widget.isFinalizing ? null : _submit,
            prefix: const Icon(FLucideIcons.shieldCheck, size: 18),
            child: Text(loc.review),
          ),
        ),
      ],
    );
  }

  void _resetCollection() {
    _inspectionTimer?.cancel();
    _inspectionGeneration++;
    _controller.clear();
    _verifiedShares.clear();
    _inputError = null;
    _isInspecting = false;
  }

  void _queueInspection(String value) {
    _inspectionTimer?.cancel();
    final generation = ++_inspectionGeneration;
    final encoded = value.trim();
    setState(() {
      _inputError = null;
      _isInspecting = encoded.isNotEmpty;
    });
    if (encoded.isEmpty) return;
    final requestHash = widget.request.hash;
    _inspectionTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_inspectShare(encoded, generation, requestHash)),
    );
  }

  Future<void> _inspectShare(
    String encoded,
    int generation,
    String requestHash,
  ) async {
    final share = await ref
        .read(walletCommandsProvider)
        .inspectMultisigSignatureShare(txHash: requestHash, encoded: encoded);
    if (!mounted ||
        generation != _inspectionGeneration ||
        requestHash != widget.request.hash ||
        _controller.text.trim() != encoded) {
      return;
    }
    if (share == null) {
      setState(() {
        _inputError = _SignatureShareInputError.invalid;
        _isInspecting = false;
      });
      return;
    }
    if (_verifiedShares.any((item) => item.signerId == share.signerId)) {
      setState(() {
        _inputError = _SignatureShareInputError.duplicate;
        _isInspecting = false;
      });
      return;
    }

    _controller.clear();
    setState(() {
      _verifiedShares.add(share);
      _inputError = null;
      _isInspecting = false;
    });
  }

  Future<void> _pasteShare() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final encoded = clipboard?.text?.trim();
    if (!mounted || encoded == null || encoded.isEmpty) return;
    if (encoded.length > _maxMultisigSignatureShareLength) {
      _inspectionTimer?.cancel();
      _inspectionGeneration++;
      _controller.text = encoded.substring(0, _maxMultisigSignatureShareLength);
      setState(() {
        _inputError = _SignatureShareInputError.invalid;
        _isInspecting = false;
      });
      return;
    }
    _controller.text = encoded;
    _queueInspection(encoded);
  }

  void _removeShare(MultisigSignatureShare share) {
    final revalidateCurrentInput =
        _inputError == _SignatureShareInputError.duplicate &&
        _controller.text.trim().isNotEmpty;
    setState(() => _verifiedShares.remove(share));
    if (revalidateCurrentInput) _queueInspection(_controller.text);
  }

  ParticipantDartPayload? _participantFor(MultisigSignatureShare? share) {
    if (share == null) return null;
    for (final participant in widget.request.participants) {
      if (participant.id == share.signerId) return participant;
    }
    return null;
  }

  String? _localizedInputError(AppLocalizations loc) => switch (_inputError) {
    _SignatureShareInputError.invalid => loc.invalid_multisig_signature_share,
    _SignatureShareInputError.duplicate =>
      loc.duplicate_multisig_signature_share,
    null => null,
  };

  Future<void> _submit() async {
    if (!_canFinalize) return;
    await widget.onFinalize(
      _verifiedShares.map((share) => share.encoded).toList(growable: false),
    );
  }
}

enum _SignatureShareInputError { invalid, duplicate }

class _SigningRequestCard extends ConsumerWidget {
  const _SigningRequestCard({required this.request});

  final MultisigSigningRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.medium,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  FLucideIcons.send,
                  size: 32,
                  color: context.theme.colors.primary,
                ),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spaces.extraSmall,
                    children: [
                      Text(
                        loc.copy_multisig_signing_request,
                        style: context.theme.typography.display.lg,
                      ),
                      Text(
                        loc.multisig_share_request_instruction,
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FButton(
              onPress: () => copyToClipboard(request.encoded, ref, loc.copied),
              prefix: const Icon(FLucideIcons.copy, size: 18),
              child: Text(loc.copy_multisig_signing_request),
            ),
            FAccordion(
              children: [
                FAccordionItem(
                  style: const FAccordionStyleDelta.delta(
                    dividerStyle: FDividerStyleDelta.delta(
                      color: Colors.transparent,
                      padding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
                    ),
                  ),
                  title: Text(loc.more_details),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spaces.medium,
                    children: [
                      _Detail(label: loc.wallet, value: request.source),
                      _Detail(label: loc.network, value: request.network),
                      _Detail(label: loc.hash, value: request.hash),
                      _Detail(
                        label: loc.threshold,
                        value:
                            '${request.threshold}/${request.participants.length}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureShareInput extends ConsumerWidget {
  const _SignatureShareInput({
    required this.controller,
    required this.error,
    required this.isInspecting,
    required this.onChanged,
    required this.onPaste,
  });

  final TextEditingController controller;
  final String? error;
  final bool isInspecting;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.small,
      children: [
        Semantics(
          label: loc.signature_share,
          textField: true,
          child: FTextField(
            control: .managed(
              controller: controller,
              onChange: (value) => onChanged(value.text),
            ),
            autocorrect: false,
            keyboardType: TextInputType.multiline,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                _maxMultisigSignatureShareLength,
              ),
            ],
            minLines: 2,
            maxLines: 5,
            hint: loc.paste_signature_share,
            error: error == null ? null : Text(error!),
          ),
        ),
        if (isInspecting)
          Text(
            loc.pending,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FButton(
            variant: .ghost,
            onPress: onPaste,
            prefix: const Icon(FLucideIcons.clipboardPaste, size: 18),
            child: Text(loc.paste_signature_share),
          ),
        ),
      ],
    );
  }
}

class _VerifiedParticipant extends ConsumerWidget {
  const _VerifiedParticipant({
    required this.signerId,
    required this.participant,
    required this.onRemove,
  });

  final int signerId;
  final ParticipantDartPayload? participant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          FLucideIcons.circleCheckBig,
          size: 16,
          color: context.theme.colors.primary,
        ),
        const SizedBox(width: Spaces.extraSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spaces.extraSmall,
            children: [
              Text('${loc.participant_id} #${signerId + 1}'),
              if (participant != null) AddressWidget(participant!.address),
            ],
          ),
        ),
        FButton.icon(
          variant: .destructive,
          onPress: onRemove,
          semanticsLabel: loc.remove_signature_share,
          child: const Icon(FLucideIcons.trash2, size: 18),
        ),
      ],
    );
  }
}

class _SignatureCollectionComplete extends ConsumerWidget {
  const _SignatureCollectionComplete();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.medium,
      children: [
        const FDivider(
          style: FDividerStyleDelta.delta(
            padding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
          ),
        ),
        Text(
          loc.ready_for_review,
          textAlign: TextAlign.center,
          style: context.theme.typography.body.md.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BroadcastReviewStep extends ConsumerWidget {
  const _BroadcastReviewStep({
    required this.review,
    required this.isBroadcasting,
    required this.onBroadcast,
    super.key,
  });

  final TransactionReviewState review;
  final bool isBroadcasting;
  final Future<void> Function(WidgetRef) onBroadcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final confirmationLabel = switch (review) {
      BurnTransaction() => loc.burn_confirmation,
      DeleteMultisigTransaction() => loc.delete_multisig_confirmation,
      _ => loc.transaction_broadcast_confirmation,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        Text(loc.review, style: context.theme.typography.display.xl2),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(Spaces.medium),
            child: _TransactionDetails(review: review),
          ),
        ),
        FCheckbox(
          value: review.isConfirmed,
          onChange: (value) => ref
              .read(transactionReviewProvider.notifier)
              .setConfirmation(value),
          label: Text(confirmationLabel),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AsyncFButton(
            isLoading: isBroadcasting,
            onPress: !review.isConfirmed || isBroadcasting
                ? null
                : () => startWithBiometricAuth(
                    ref,
                    callback: onBroadcast,
                    reason: loc.please_authenticate_tx,
                  ),
            prefix: const Icon(FLucideIcons.send, size: 18),
            child: Text(loc.broadcast),
          ),
        ),
      ],
    );
  }
}

String? _transactionHash(TransactionReviewState review) => switch (review) {
  SingleTransferTransaction(:final txHash) ||
  BurnTransaction(:final txHash) ||
  DeleteMultisigTransaction(:final txHash) => txHash,
  _ => null,
};

class _TransactionDetails extends ConsumerWidget {
  const _TransactionDetails({required this.review});

  final TransactionReviewState review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.medium,
      children: switch (review) {
        SingleTransferTransaction transaction => [
          _Detail(label: loc.transaction_type, value: loc.transfer),
          _Detail(label: loc.asset, value: transaction.name),
          _Detail(label: loc.amount, value: transaction.amount),
          _Detail(label: loc.fee, value: transaction.fee),
          _Detail(label: loc.hash, value: transaction.txHash),
          _AddressDetail(
            label: loc.receiver,
            address: transaction.destinationAddress.address,
          ),
          if (transaction.destinationAddress.isIntegrated)
            _Detail(
              label: loc.payment_id,
              value: transaction.destinationAddress.data.toString(),
            ),
        ],
        BurnTransaction transaction => [
          _Detail(label: loc.transaction_type, value: loc.burn),
          _Detail(
            label: loc.asset,
            value: transaction.name.isEmpty
                ? transaction.asset
                : transaction.name,
          ),
          _Detail(label: loc.amount, value: transaction.amount),
          _Detail(label: loc.fee, value: transaction.fee),
          _Detail(label: loc.hash, value: transaction.txHash),
        ],
        DeleteMultisigTransaction transaction => [
          _Detail(label: loc.transaction_type, value: loc.multisig_removal),
          _Detail(label: loc.fee, value: transaction.fee),
          _Detail(label: loc.hash, value: transaction.txHash),
        ],
        _ => const [],
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.extraSmall,
      children: [
        Text(
          label,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        SelectableText(value),
      ],
    );
  }
}

class _AddressDetail extends StatelessWidget {
  const _AddressDetail({required this.label, required this.address});

  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.extraSmall,
      children: [Text(label), AddressWidget(address)],
    );
  }
}

class _BroadcastComplete extends ConsumerWidget {
  const _BroadcastComplete({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      key: const ValueKey('broadcast-complete'),
      spacing: Spaces.large,
      children: [
        Icon(
          FLucideIcons.circleCheckBig,
          size: 72,
          color: context.theme.colors.primary,
        ),
        Text(
          loc.transaction_broadcast_message,
          textAlign: TextAlign.center,
          style: context.theme.typography.display.xl,
        ),
        FButton(onPress: onClose, child: Text(loc.close)),
      ],
    );
  }
}

class _EmptyReview extends ConsumerWidget {
  const _EmptyReview({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      spacing: Spaces.large,
      children: [
        const Icon(FLucideIcons.fileQuestion, size: 64),
        Text(loc.no_data),
        FButton(onPress: onClose, child: Text(loc.close)),
      ],
    );
  }
}
