import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/signature_collection_widgets.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

const _maxMultisigSignatureShareLength = 1024;
const _multisigSignatureInspectionDelay = Duration(milliseconds: 500);

Duration _signatureMotionDuration(BuildContext context) {
  final animationsDisabled =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return animationsDisabled
      ? Duration.zero
      : const Duration(milliseconds: AppDurations.animNormal);
}

class SignatureCollectionStep extends ConsumerStatefulWidget {
  const SignatureCollectionStep({
    required this.request,
    required this.isFinalizing,
    required this.onFinalize,
    super.key,
  });

  final MultisigSigningRequest request;
  final bool isFinalizing;
  final Future<void> Function(List<String>) onFinalize;

  @override
  ConsumerState<SignatureCollectionStep> createState() =>
      _SignatureCollectionStepState();
}

class _SignatureCollectionStepState
    extends ConsumerState<SignatureCollectionStep> {
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
        SigningRequestCard(request: widget.request),
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
                    AnimatedSignatureEntryState(
                      isInputVisible: _isInputVisible,
                      controller: _controller,
                      error: _localizedInputError(loc),
                      isInputEnabled:
                          !_isSettlingShare &&
                          !_hasRequiredShares &&
                          !widget.isFinalizing,
                      duration: motionDuration,
                      maxLength: _maxMultisigSignatureShareLength,
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
                    AnimatedSignatureList(
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
      (context, animation) => AnimatedVerifiedParticipant(
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
