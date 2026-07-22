import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_complete.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_configuration.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_review.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';

class SetupMultisig extends ConsumerStatefulWidget {
  const SetupMultisig({super.key});

  @override
  ConsumerState<SetupMultisig> createState() => _SetupMultisigState();
}

class _SetupMultisigState extends ConsumerState<SetupMultisig> {
  List<String> _participants = [];
  int _threshold = 1;

  TransactionSummary? _transaction;
  bool _confirmed = false;
  bool _isPreparing = false;
  bool _isBroadcasting = false;
  bool _isComplete = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final title = _isComplete
        ? loc.multisig_setup_broadcast_title
        : _transaction == null
        ? loc.multisig_setup_title
        : loc.multisig_setup_review_title;
    final transitionDuration =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : const Duration(milliseconds: AppDurations.animFast);

    final Widget content;
    if (_isComplete) {
      content = MultisigSetupComplete(
        key: const ValueKey('multisig-complete'),
        loc: loc,
        onFinish: _finish,
      );
    } else if (_transaction case final transaction?) {
      content = MultisigSetupReview(
        key: const ValueKey('multisig-review'),
        loc: loc,
        hash: transaction.hash,
        fee: formatXelis(transaction.fee, network),
        threshold: _threshold,
        participants: _participants,
        confirmed: _confirmed,
        isBroadcasting: _isBroadcasting,
        onConfirmationChanged: (value) => setState(() => _confirmed = value),
        onEdit: _editConfiguration,
        onActivate: () => startWithBiometricAuth(
          ref,
          callback: _broadcast,
          reason: loc.please_authenticate_tx,
        ),
      );
    } else {
      content = MultisigSetupConfiguration(
        key: const ValueKey('multisig-configuration'),
        loc: loc,
        participants: _participants,
        threshold: _threshold,
        isPreparing: _isPreparing,
        validateParticipant: _validateParticipant,
        onParticipantsChanged: _updateParticipants,
        onThresholdChanged: _updateThreshold,
        onPrepare: _prepare,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isPreparing && !_isBroadcasting) {
          _handleBack();
        }
      },
      child: FScaffold(
        header: FHeader.nested(
          title: Text(title),
          prefixes: [
            Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: FHeaderAction.back(
                onPress: _isPreparing || _isBroadcasting ? null : _handleBack,
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
                constraints: const BoxConstraints(maxWidth: 900),
                child: AnimatedSwitcher(
                  duration: transitionDuration,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateParticipant(String rawAddress) {
    final loc = ref.read(appLocalizationsProvider);
    final address = rawAddress.trim();
    if (address.isEmpty) return loc.field_required_error;
    if (!ref.read(walletCommandsProvider).isAddressValidForMultisig(address)) {
      return loc.multisig_address_validation_error;
    }
    if (_participants.contains(address)) {
      return loc.multisig_participant_duplicated;
    }
    return null;
  }

  void _updateParticipants(List<String> participants) {
    setState(() {
      _participants = List.of(participants);
      if (_participants.isEmpty) {
        _threshold = 1;
      } else if (_threshold > _participants.length) {
        _threshold = _participants.length;
      }
    });
  }

  void _updateThreshold(int threshold) {
    if (_participants.isEmpty ||
        threshold < 1 ||
        threshold > _participants.length) {
      return;
    }
    setState(() => _threshold = threshold);
  }

  Future<void> _prepare() async {
    if (_isPreparing || _participants.isEmpty) return;

    final participants = List.of(_participants, growable: false);
    final threshold = _threshold;
    final commands = ref.read(walletCommandsProvider);
    setState(() => _isPreparing = true);
    try {
      final transaction = await commands.setupMultisig(
        participants: participants,
        threshold: threshold,
      );
      if (transaction == null) return;
      if (!mounted) {
        await commands.cancelTransaction(hash: transaction.hash);
        return;
      }
      setState(() => _transaction = transaction);
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  Future<void> _broadcast(WidgetRef ref) async {
    if (_isBroadcasting) return;
    setState(() => _isBroadcasting = true);
    try {
      final broadcasted = await ref
          .read(walletCommandsProvider)
          .broadcastTx(hash: _transaction!.hash);
      if (!mounted || broadcasted == null) return;

      final loc = ref.read(appLocalizationsProvider);
      final toast = ref.read(toastProvider.notifier);
      switch (broadcasted) {
        case TransactionBroadcastResult.submitted:
          ref.read(multisigPendingStateProvider.notifier).pendingState();
          toast.showEvent(description: loc.transaction_broadcast_message);
          setState(() => _isComplete = true);
        case TransactionBroadcastResult.retryable:
          toast.showWarning(title: loc.transaction_broadcast_retry_message);
        case TransactionBroadcastResult.rejected:
        case TransactionBroadcastResult.localFailure:
          toast.showError(
            description: loc.transaction_broadcast_recreate_message,
          );
          setState(() {
            _transaction = null;
            _confirmed = false;
          });
        case TransactionBroadcastResult.submittedNeedsResync:
          ref.read(multisigPendingStateProvider.notifier).pendingState();
          toast.showWarning(title: loc.transaction_broadcast_resync_message);
          setState(() => _isComplete = true);
      }
    } finally {
      if (mounted) setState(() => _isBroadcasting = false);
    }
  }

  Future<void> _editConfiguration() async {
    final transaction = _transaction;
    if (transaction != null) {
      await ref
          .read(walletCommandsProvider)
          .cancelTransaction(hash: transaction.hash);
    }
    if (!mounted) return;
    setState(() {
      _transaction = null;
      _confirmed = false;
    });
  }

  Future<void> _handleBack() async {
    if (_transaction != null && !_isComplete) {
      await _editConfiguration();
      return;
    }
    if (!mounted) return;
    _finish();
  }

  void _finish() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AuthAppScreen.multisig.toPath);
    }
  }
}
