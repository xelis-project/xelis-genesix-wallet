import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/broadcast_review_step.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/review_state_widgets.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/signature_collection_step.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';

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
        ? BroadcastComplete(onClose: _finish)
        : switch (review) {
            SignaturePending(:final request) => SignatureCollectionStep(
              key: ValueKey('signature-${request.hash}-${request.threshold}'),
              request: request,
              isFinalizing: _isFinalizing,
              onFinalize: _finalize,
            ),
            SingleTransferTransaction() ||
            BurnTransaction() ||
            DeleteMultisigTransaction() => BroadcastReviewStep(
              key: ValueKey('broadcast-${_transactionHash(review)}'),
              review: review,
              isBroadcasting: _isBroadcasting,
              onBroadcast: _broadcast,
            ),
            Initial() => EmptyReview(onClose: _finish),
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

String? _transactionHash(TransactionReviewState review) => switch (review) {
  SingleTransferTransaction(:final txHash) ||
  BurnTransaction(:final txHash) ||
  DeleteMultisigTransaction(:final txHash) => txHash,
  _ => null,
};
