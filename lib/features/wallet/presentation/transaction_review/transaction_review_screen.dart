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
const _multisigSignatureInspectionDelay = Duration(milliseconds: 500);

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
              key: ValueKey('signature-${request.hash}-${request.threshold}'),
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
  final _signatureListKey = GlobalKey<AnimatedListState>();
  final List<MultisigSignatureShare> _verifiedShares = [];
  Timer? _inspectionTimer;
  _SignatureShareInputError? _inputError;
  bool _isInspecting = false;
  int _inspectionGeneration = 0;
  int _presentationGeneration = 0;
  String _observedInputText = '';
  bool _isSettlingShare = false;
  bool _isInputVisible = true;
  bool _isInputExitComplete = false;

  bool get _hasRequiredShares =>
      _verifiedShares.length == widget.request.threshold;

  bool get _canFinalize =>
      !_isInspecting &&
      !_isSettlingShare &&
      _hasRequiredShares &&
      !_isInputVisible &&
      _isInputExitComplete;

  @override
  void dispose() {
    _inspectionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final motionDuration = _signatureMotionDuration(context);

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
                      variant: _hasRequiredShares ? .primary : .secondary,
                      child: Text(
                        '${_verifiedShares.length}/${widget.request.threshold}',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AnimatedSignatureEntryState(
                      isInputVisible: _isInputVisible,
                      controller: _controller,
                      error: _localizedInputError(loc),
                      isInputEnabled:
                          !_isSettlingShare &&
                          !_hasRequiredShares &&
                          !widget.isFinalizing,
                      duration: motionDuration,
                      onChanged: _handleInputChanged,
                      onPaste: _pasteShare,
                    ),
                    AnimatedContainer(
                      duration: motionDuration,
                      curve: Curves.easeInOutCubic,
                      height: _verifiedShares.isNotEmpty && _isInputVisible
                          ? Spaces.medium
                          : 0,
                    ),
                    _AnimatedSignatureList(
                      listKey: _signatureListKey,
                      shares: _verifiedShares,
                      participants: {
                        for (final participant in widget.request.participants)
                          participant.id: participant,
                      },
                      canRemove: !_isSettlingShare && !widget.isFinalizing,
                      onRemove: _removeShare,
                    ),
                  ],
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

  void _handleInputChanged(String value) {
    if (value == _observedInputText) return;

    _observedInputText = value;
    _scheduleInspection(value);
  }

  void _scheduleInspection(String value, {bool immediately = false}) {
    if (_isSettlingShare || _hasRequiredShares || widget.isFinalizing) return;

    _inspectionTimer?.cancel();
    final generation = ++_inspectionGeneration;
    final encoded = value.trim();
    setState(() {
      _inputError = null;
      _isInspecting = false;
    });
    if (encoded.isEmpty) return;
    final requestHash = widget.request.hash;
    if (immediately) {
      unawaited(_inspectShare(encoded, generation, requestHash));
      return;
    }
    _inspectionTimer = Timer(
      _multisigSignatureInspectionDelay,
      () => unawaited(_inspectShare(encoded, generation, requestHash)),
    );
  }

  Future<void> _inspectShare(
    String encoded,
    int generation,
    String requestHash,
  ) async {
    if (!mounted ||
        generation != _inspectionGeneration ||
        requestHash != widget.request.hash ||
        _controller.text.trim() != encoded) {
      return;
    }

    setState(() => _isInspecting = true);
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

    final insertionIndex = _verifiedShares.length;
    final animatedList = _signatureListKey.currentState;
    final duration = _signatureMotionDuration(context);
    setState(() {
      _verifiedShares.add(share);
      _inputError = null;
      _isInspecting = false;
      _isSettlingShare = true;
      _isInputExitComplete = false;
    });
    animatedList?.insertItem(insertionIndex, duration: duration);
    if (_hasRequiredShares) {
      _startCompletionSequence(duration);
    } else {
      _startIntermediateShareSequence(duration);
    }
  }

  Future<void> _pasteShare() async {
    if (_isSettlingShare || _hasRequiredShares || widget.isFinalizing) return;

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final encoded = clipboard?.text?.trim();
    if (!mounted || encoded == null || encoded.isEmpty) return;
    if (encoded.length > _maxMultisigSignatureShareLength) {
      _inspectionTimer?.cancel();
      _inspectionGeneration++;
      _setInputText(encoded.substring(0, _maxMultisigSignatureShareLength));
      setState(() {
        _inputError = _SignatureShareInputError.invalid;
        _isInspecting = false;
      });
      return;
    }
    _setInputText(encoded);
    _scheduleInspection(encoded, immediately: true);
  }

  void _removeShare(MultisigSignatureShare share) {
    final index = _verifiedShares.indexWhere(
      (item) => item.signerId == share.signerId,
    );
    if (index < 0) return;

    final wasComplete = _hasRequiredShares;
    final removedShare = _verifiedShares[index];
    final participant = _participantFor(removedShare);
    final animatedList = _signatureListKey.currentState;
    final duration = _signatureMotionDuration(context);
    final wasSettling = _isSettlingShare;
    final revalidateCurrentInput =
        _inputError == _SignatureShareInputError.duplicate &&
        _controller.text.trim().isNotEmpty;
    _presentationGeneration++;
    if (wasSettling) _clearInput();
    setState(() {
      _verifiedShares.removeAt(index);
      _isSettlingShare = false;
      _isInputExitComplete = false;
    });
    animatedList?.removeItem(
      index,
      (context, animation) => _AnimatedVerifiedParticipant(
        animation: animation,
        signerId: removedShare.signerId,
        participant: participant,
        onRemove: null,
      ),
      duration: duration,
    );
    if (wasComplete || !_isInputVisible) {
      _startIncompleteSequence(duration);
    }
    if (revalidateCurrentInput) {
      _scheduleInspection(_controller.text, immediately: true);
    }
  }

  void _startIntermediateShareSequence(Duration duration) {
    final generation = ++_presentationGeneration;

    if (duration == Duration.zero) {
      _clearAcceptedShare();
      return;
    }

    unawaited(_finishIntermediateShareSequence(generation, duration));
  }

  Future<void> _finishIntermediateShareSequence(
    int generation,
    Duration duration,
  ) async {
    await Future<void>.delayed(duration);
    if (!_isCurrentPresentation(generation) || _hasRequiredShares) return;

    _clearAcceptedShare();
  }

  void _clearAcceptedShare() {
    _clearInput();
    setState(() => _isSettlingShare = false);
  }

  void _setInputText(String value) {
    _observedInputText = value;
    _controller.text = value;
  }

  void _clearInput() => _setInputText('');

  void _startCompletionSequence(Duration duration) {
    final generation = ++_presentationGeneration;

    if (duration == Duration.zero) {
      _clearInput();
      setState(() {
        _isSettlingShare = false;
        _isInputVisible = false;
        _isInputExitComplete = true;
      });
      return;
    }

    unawaited(_showCompletionSequence(generation, duration));
  }

  Future<void> _showCompletionSequence(
    int generation,
    Duration duration,
  ) async {
    await Future<void>.delayed(duration);
    if (!_isCurrentPresentation(generation) || !_hasRequiredShares) return;

    setState(() => _isInputVisible = false);
    await Future<void>.delayed(duration);
    if (!_isCurrentPresentation(generation) || !_hasRequiredShares) return;

    _clearInput();
    setState(() {
      _isSettlingShare = false;
      _isInputExitComplete = true;
    });
  }

  void _startIncompleteSequence(Duration duration) {
    final generation = ++_presentationGeneration;

    if (duration == Duration.zero) {
      setState(() => _isInputVisible = true);
      return;
    }

    unawaited(_showIncompleteSequence(generation, duration));
  }

  Future<void> _showIncompleteSequence(
    int generation,
    Duration duration,
  ) async {
    await Future<void>.delayed(duration);
    if (!_isCurrentPresentation(generation) || _hasRequiredShares) return;

    setState(() => _isInputVisible = true);
  }

  bool _isCurrentPresentation(int generation) =>
      mounted && generation == _presentationGeneration;

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

enum _SignatureRevealDirection { fromTop, fromEnd }

Duration _signatureMotionDuration(BuildContext context) {
  final animationsDisabled =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return animationsDisabled
      ? Duration.zero
      : const Duration(milliseconds: AppDurations.animNormal);
}

class _AnimatedSignatureList extends StatelessWidget {
  const _AnimatedSignatureList({
    required this.listKey,
    required this.shares,
    required this.participants,
    required this.canRemove,
    required this.onRemove,
  });

  final GlobalKey<AnimatedListState> listKey;
  final List<MultisigSignatureShare> shares;
  final Map<int, ParticipantDartPayload> participants;
  final bool canRemove;
  final ValueChanged<MultisigSignatureShare> onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedList.separated(
      key: listKey,
      initialItemCount: shares.length,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      itemBuilder: (context, index, animation) {
        final share = shares[index];
        return _AnimatedVerifiedParticipant(
          key: ValueKey(share.signerId),
          animation: animation,
          signerId: share.signerId,
          participant: participants[share.signerId],
          onRemove: canRemove ? () => onRemove(share) : null,
        );
      },
      separatorBuilder: (context, index, animation) =>
          _AnimatedSignatureSeparator(animation: animation),
      removedSeparatorBuilder: (context, index, animation) =>
          _AnimatedSignatureSeparator(animation: animation),
    );
  }
}

class _AnimatedSignatureSeparator extends StatelessWidget {
  const _AnimatedSignatureSeparator({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      alignment: AlignmentDirectional.topStart,
      child: const SizedBox(height: Spaces.medium),
    );
  }
}

class _AnimatedVerifiedParticipant extends StatelessWidget {
  const _AnimatedVerifiedParticipant({
    required this.animation,
    required this.signerId,
    required this.participant,
    required this.onRemove,
    super.key,
  });

  final Animation<double> animation;
  final int signerId;
  final ParticipantDartPayload? participant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _SignatureRevealTransition(
      animation: animation,
      direction: _SignatureRevealDirection.fromEnd,
      child: _VerifiedParticipant(
        signerId: signerId,
        participant: participant,
        onRemove: onRemove,
      ),
    );
  }
}

class _AnimatedSignatureEntryState extends StatelessWidget {
  const _AnimatedSignatureEntryState({
    required this.isInputVisible,
    required this.controller,
    required this.error,
    required this.isInputEnabled,
    required this.duration,
    required this.onChanged,
    required this.onPaste,
  });

  final bool isInputVisible;
  final TextEditingController controller;
  final String? error;
  final bool isInputEnabled;
  final Duration duration;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, animation) => _SignatureRevealTransition(
          animation: animation,
          direction: _SignatureRevealDirection.fromTop,
          child: child,
        ),
        child: isInputVisible
            ? _SignatureShareInput(
                key: const ValueKey('signature-input'),
                controller: controller,
                error: error,
                isEnabled: isInputEnabled,
                onChanged: onChanged,
                onPaste: onPaste,
              )
            : const SizedBox.shrink(key: ValueKey('signature-empty')),
      ),
    );
  }
}

class _SignatureRevealTransition extends StatelessWidget {
  const _SignatureRevealTransition({
    required this.animation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final _SignatureRevealDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final begin = switch (direction) {
      _SignatureRevealDirection.fromTop => const Offset(0, -28),
      _SignatureRevealDirection.fromEnd => Offset(
        Directionality.of(context) == TextDirection.ltr ? 32 : -32,
        0,
      ),
    };

    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        alignment: AlignmentDirectional.topStart,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Transform.translate(
            offset: Offset.lerp(begin, Offset.zero, curved.value)!,
            child: child,
          ),
        ),
      ),
    );
  }
}

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
    required this.isEnabled,
    required this.onChanged,
    required this.onPaste,
    super.key,
  });

  final TextEditingController controller;
  final String? error;
  final bool isEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: loc.signature_share,
          textField: true,
          child: FTextField(
            enabled: isEnabled,
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
            minLines: 3,
            maxLines: 3,
            hint: loc.paste_signature_share,
            error: error == null ? null : Text(error!),
          ),
        ),
        const SizedBox(height: Spaces.small),
        Align(
          alignment: Alignment.centerRight,
          child: FButton(
            variant: .ghost,
            onPress: isEnabled ? onPaste : null,
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
