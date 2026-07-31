import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/sign_transaction/components/signing_request_entry.dart';
import 'package:genesix/features/wallet/presentation/sign_transaction/components/signing_request_review.dart';
import 'package:genesix/features/wallet/presentation/sign_transaction/components/signature_share_ready.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

const _maxMultisigSigningRequestLength = 3 * 1024 * 1024;

enum _SigningRequestInputError { required, invalid }

enum _SigningFlowDirection { forward, backward }

class SignTransactionContent extends ConsumerStatefulWidget {
  const SignTransactionContent({super.key});

  @override
  ConsumerState<SignTransactionContent> createState() =>
      _SignTransactionContentState();
}

class _SignTransactionContentState
    extends ConsumerState<SignTransactionContent> {
  final _requestController = TextEditingController();
  final _scrollController = ScrollController();

  MultisigSigningRequest? _request;
  MultisigSignatureShare? _signatureShare;
  NativeWalletRepository? _requestRepository;
  _SigningRequestInputError? _inputError;
  String _observedInputText = '';
  bool _deleteConfirmed = false;
  bool _isInspecting = false;
  bool _isAuthenticating = false;
  bool _isSigning = false;
  bool _signingFailed = false;
  bool _copied = false;
  _SigningFlowDirection _transitionDirection = _SigningFlowDirection.forward;

  @override
  void dispose() {
    _requestController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NativeWalletRepository?>(
      activeWalletRepositoryProvider,
      _handleActiveRepositoryChanged,
    );
    final loc = ref.watch(appLocalizationsProvider);
    final runtime = ref.watch(walletRuntimeProvider);
    final isNodeAvailable =
        runtime.isOnline &&
        runtime.connectionPhase == WalletConnectionPhase.connected;
    final nodeRequirementMessage = switch (runtime.connectionPhase) {
      WalletConnectionPhase.offline => loc.action_not_available_offline,
      WalletConnectionPhase.connecting ||
      WalletConnectionPhase.reconnecting => loc.action_wait_for_node_connection,
      _ => loc.action_requires_connected_node,
    };
    final transitionDuration =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : const Duration(milliseconds: AppDurations.animFast);

    final Widget content;
    if (_signatureShare case final share?) {
      content = SignatureShareReady(
        key: ValueKey('signature-ready-${share.requestHash}'),
        share: share,
        participant: _participantFor(share.signerId),
        copied: _copied,
        onCopy: _copySignatureShare,
        onRestart: _restart,
      );
    } else if (_request case final request?) {
      content = SigningRequestReview(
        key: ValueKey('signing-review-${request.hash}'),
        request: request,
        runtime: runtime,
        participant: _participantFor(request.signerId),
        isNodeAvailable: isNodeAvailable,
        nodeRequirementMessage: nodeRequirementMessage,
        deleteConfirmed: _deleteConfirmed,
        isSigning: _isAuthenticating || _isSigning,
        signingFailed: _signingFailed,
        onDeleteConfirmationChanged: _setDeleteConfirmation,
        onEdit: _editRequest,
        onSign: _startSigning,
      );
    } else {
      content = SigningRequestEntry(
        key: const ValueKey('signing-request-entry'),
        controller: _requestController,
        maxLength: _maxMultisigSigningRequestLength,
        isNodeAvailable: isNodeAvailable,
        nodeRequirementMessage: nodeRequirementMessage,
        isInspecting: _isInspecting,
        error: switch (_inputError) {
          _SigningRequestInputError.required => loc.field_required_error,
          _SigningRequestInputError.invalid =>
            loc.invalid_multisig_signing_request,
          null => null,
        },
        onChanged: _handleRequestChanged,
        onPaste: _pasteRequest,
        onInspect: _inspectRequest,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - Spaces.medium * 2).clamp(
                0.0,
                double.infinity,
              )
            : 0.0;

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(Spaces.medium),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 900,
                minHeight: minimumHeight,
              ),
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: transitionDuration,
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  layoutBuilder: _buildTransitionLayout,
                  transitionBuilder: (child, animation) => _buildTransition(
                    child,
                    animation,
                    isIncoming: child.key == content.key,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransition(
    Widget child,
    Animation<double> animation, {
    required bool isIncoming,
  }) {
    final direction = _transitionDirection == _SigningFlowDirection.forward
        ? 1.0
        : -1.0;
    final offset = Tween<Offset>(
      begin: Offset(isIncoming ? direction : -direction, 0),
      end: Offset.zero,
    ).animate(animation);

    return SlideTransition(position: offset, child: child);
  }

  Widget _buildTransitionLayout(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [...previousChildren, ?currentChild],
    );
  }

  ParticipantDartPayload? _participantFor(int? signerId) {
    if (signerId == null) return null;
    final participants = _request?.participants;
    if (participants == null) return null;
    for (final participant in participants) {
      if (participant.id == signerId) return participant;
    }
    return null;
  }

  void _handleRequestChanged(String value) {
    if (value == _observedInputText) return;
    _observedInputText = value;
    if (_inputError != null) {
      setState(() => _inputError = null);
    }
  }

  void _handleActiveRepositoryChanged(
    NativeWalletRepository? previous,
    NativeWalletRepository? next,
  ) {
    final requestRepository = _requestRepository;
    if (requestRepository == null || identical(next, requestRepository)) return;

    _changeStep(() {
      _request = null;
      _requestRepository = null;
      _signatureShare = null;
      _inputError = null;
      _observedInputText = '';
      _deleteConfirmed = false;
      _signingFailed = false;
      _copied = false;
      _requestController.clear();
    }, direction: _SigningFlowDirection.backward);
  }

  Future<void> _pasteRequest() async {
    if (_isInspecting) return;

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = clipboard?.text;
    if (text == null || text.isEmpty) return;
    if (text.length > _maxMultisigSigningRequestLength) {
      setState(() => _inputError = _SigningRequestInputError.invalid);
      return;
    }

    _requestController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _handleRequestChanged(text);
  }

  Future<void> _inspectRequest() async {
    if (_isInspecting) return;

    final encoded = _requestController.text.trim();
    if (encoded.isEmpty) {
      setState(() => _inputError = _SigningRequestInputError.required);
      return;
    }

    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _inputError = null;
      _isInspecting = true;
    });
    try {
      final request = await ref
          .read(walletCommandsProvider)
          .inspectMultisigSigningRequest(encoded);
      if (!mounted ||
          _requestController.text.trim() != encoded ||
          !identical(ref.read(activeWalletRepositoryProvider), repository)) {
        return;
      }
      if (request == null) {
        final runtime = ref.read(walletRuntimeProvider);
        final nodeStillAvailable =
            runtime.isOnline &&
            runtime.connectionPhase == WalletConnectionPhase.connected;
        if (nodeStillAvailable) {
          setState(() => _inputError = _SigningRequestInputError.invalid);
        }
        return;
      }

      _changeStep(() {
        _request = request;
        _requestRepository = repository;
        _signatureShare = null;
        _deleteConfirmed = false;
        _signingFailed = false;
        _copied = false;
      });
    } finally {
      if (mounted) setState(() => _isInspecting = false);
    }
  }

  void _setDeleteConfirmation(bool value) {
    setState(() => _deleteConfirmed = value);
  }

  void _editRequest() {
    if (_isAuthenticating || _isSigning) return;
    _changeStep(() {
      _request = null;
      _requestRepository = null;
      _signatureShare = null;
      _deleteConfirmed = false;
      _signingFailed = false;
      _copied = false;
    }, direction: _SigningFlowDirection.backward);
  }

  Future<void> _startSigning() async {
    final request = _request;
    final requestRepository = _requestRepository;
    if (request == null ||
        requestRepository == null ||
        !identical(
          ref.read(activeWalletRepositoryProvider),
          requestRepository,
        ) ||
        request.signerId == null ||
        _isAuthenticating ||
        _isSigning) {
      return;
    }

    final loc = ref.read(appLocalizationsProvider);
    setState(() => _isAuthenticating = true);
    try {
      await startWithBiometricAuth(
        ref,
        callback: (authenticatedRef) =>
            _signRequest(authenticatedRef, request.hash, requestRepository),
        reason: loc.please_authenticate_tx,
      );
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _signRequest(
    WidgetRef authenticatedRef,
    String expectedRequestHash,
    NativeWalletRepository expectedRepository,
  ) async {
    final request = _request;
    if (request == null ||
        request.hash != expectedRequestHash ||
        !identical(
          authenticatedRef.read(activeWalletRepositoryProvider),
          expectedRepository,
        ) ||
        request.signerId == null ||
        (request.transaction is MultisigSigningTransaction_DeleteMultisig &&
            !_deleteConfirmed) ||
        _isSigning) {
      return;
    }

    setState(() {
      _isSigning = true;
      _signingFailed = false;
    });
    try {
      final share = await authenticatedRef
          .read(walletCommandsProvider)
          .signMultisigSigningRequest(request.encoded);
      if (!mounted ||
          _request?.hash != request.hash ||
          !identical(
            authenticatedRef.read(activeWalletRepositoryProvider),
            expectedRepository,
          )) {
        return;
      }
      if (share == null || share.requestHash != request.hash) {
        setState(() => _signingFailed = true);
        return;
      }

      _changeStep(() {
        _signatureShare = share;
        _copied = false;
      });
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  void _copySignatureShare() {
    final share = _signatureShare;
    if (share == null) return;

    final loc = ref.read(appLocalizationsProvider);
    copyToClipboard(share.encoded, ref, loc.copied);
    setState(() => _copied = true);
  }

  void _restart() {
    if (_isAuthenticating || _isSigning) return;
    _changeStep(() {
      _request = null;
      _requestRepository = null;
      _signatureShare = null;
      _inputError = null;
      _observedInputText = '';
      _deleteConfirmed = false;
      _signingFailed = false;
      _copied = false;
      _requestController.clear();
    }, direction: _SigningFlowDirection.backward);
  }

  void _changeStep(
    VoidCallback update, {
    _SigningFlowDirection direction = _SigningFlowDirection.forward,
  }) {
    setState(() {
      _transitionDirection = direction;
      update();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: AppDurations.animFast),
        curve: Curves.easeOutCubic,
      );
    });
  }
}
