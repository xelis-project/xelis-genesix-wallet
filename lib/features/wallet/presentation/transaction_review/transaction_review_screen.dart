import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_policy.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/broadcast_review_step.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/review_state_widgets.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/signature_collection_step.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

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
    final isFullHeightContent = review.isBroadcasted || review is Initial;
    final content = review.isBroadcasted
        ? BroadcastComplete(onClose: _finish)
        : switch (review) {
            SignaturePending(:final request) => SignatureCollectionStep(
              key: ObjectKey(request),
              request: request,
              isFinalizing: _isFinalizing,
              onFinalize: _finalize,
            ),
            SingleTransferTransaction() ||
            BurnTransaction() ||
            DeleteMultisigTransaction() => BroadcastReviewStep(
              key: ValueKey('broadcast-${transactionReviewHash(review)}'),
              review: review,
              isBroadcasting: _isBroadcasting,
              onBroadcast: (callbackRef) => _broadcast(callbackRef, review),
            ),
            Initial() => EmptyReview(onClose: _finish),
          };
    final pageContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: content,
        ),
      ),
    );

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
          child: isFullHeightContent
              ? Padding(
                  padding: const EdgeInsets.all(Spaces.medium),
                  child: pageContent,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(Spaces.medium),
                  child: pageContent,
                ),
        ),
      ),
    );
  }

  Future<void> _finalize(
    List<wallet_flutter.XelisWalletMultisigSignatureShare> shares,
  ) async {
    if (_isFinalizing) return;
    final review = ref.read(transactionReviewProvider);
    if (review is! SignaturePending) return;
    final commands = ref.read(walletCommandsProvider);

    setState(() => _isFinalizing = true);
    try {
      final transaction = await commands.finalizeMultisigTransaction(
        request: review.request,
        shares: shares,
        sessionIdentity: review.sessionIdentity,
      );
      if (transaction == null) return;
      if (!mounted) {
        await commands.cancelPreparedTransaction(
          transaction: transaction,
          sessionIdentity: review.sessionIdentity,
        );
        return;
      }

      final latest = ref.read(transactionReviewProvider);
      if (latest is! SignaturePending ||
          !identical(latest.request, review.request) ||
          !identical(
            ref.read(activeWalletRepositoryProvider),
            review.sessionIdentity,
          )) {
        talker.warning('Multisig review changed during finalization');
        await commands.cancelPreparedTransaction(
          transaction: transaction,
          sessionIdentity: review.sessionIdentity,
        );
        return;
      }
      final notifier = ref.read(transactionReviewProvider.notifier);
      notifier.setPreparedMultisigTransaction(
        transaction,
        sessionIdentity: review.sessionIdentity,
      );
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  Future<void> _broadcast(
    WidgetRef callbackRef,
    TransactionReviewState reviewed,
  ) async {
    if (_isBroadcasting) return;
    final current = callbackRef.read(transactionReviewProvider);
    if (!isSameConfirmedTransactionReview(current, reviewed)) {
      talker.warning('Transaction review changed during authentication');
      return;
    }

    final hash = transactionReviewHash(reviewed);
    if (hash == null) return;

    setState(() => _isBroadcasting = true);
    try {
      final prepared = transactionReviewPrepared(reviewed);
      if (prepared == null) return;
      final result = await callbackRef
          .read(walletCommandsProvider)
          .broadcastPreparedTx(
            transaction: prepared,
            sessionIdentity: transactionReviewSessionIdentity(reviewed)!,
          );
      if (!mounted || result == null) return;
      final latest = callbackRef.read(transactionReviewProvider);
      if (!isSameConfirmedTransactionReview(latest, reviewed)) {
        talker.warning('Transaction review changed during broadcast');
        return;
      }
      _handlePreparedBroadcastResult(callbackRef, reviewed, result);
    } finally {
      if (mounted) setState(() => _isBroadcasting = false);
    }
  }

  void _handlePreparedBroadcastResult(
    WidgetRef callbackRef,
    TransactionReviewState reviewed,
    PreparedTransactionBroadcastResult result,
  ) {
    final loc = callbackRef.read(appLocalizationsProvider);
    final toast = callbackRef.read(toastProvider.notifier);
    switch (preparedTransactionReviewAction(result.disposition)) {
      case PreparedTransactionReviewAction.markBroadcasted:
        callbackRef.read(transactionReviewProvider.notifier).broadcast();
        if (reviewed is DeleteMultisigTransaction) {
          callbackRef
              .read(multisigPendingStateProvider.notifier)
              .pendingState();
        }
        toast.showEvent(description: loc.transaction_broadcast_message);
      case PreparedTransactionReviewAction.retainForRetry:
        toast.showFailure(
          description: loc.transaction_broadcast_retry_message,
          failure: result.failure!,
        );
      case PreparedTransactionReviewAction.resetAndClose:
        callbackRef.read(transactionReviewProvider.notifier).reset();
        toast.showFailure(
          description: loc.transaction_broadcast_recreate_message,
          failure: result.failure!,
        );
        context.pop();
      case PreparedTransactionReviewAction.markBroadcastedNeedsResync:
        callbackRef.read(transactionReviewProvider.notifier).broadcast();
        if (reviewed is DeleteMultisigTransaction) {
          callbackRef
              .read(multisigPendingStateProvider.notifier)
              .pendingState();
        }
        toast.showFailure(
          description: loc.transaction_broadcast_resync_message,
          failure: result.failure!,
        );
    }
  }

  Future<void> _close(TransactionReviewState review) async {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    try {
      if (review case SignaturePending(:final request)) {
        final commands = ref.read(walletCommandsProvider);
        final canceled = await commands.cancelPendingMultisigRequest(
          request: request,
          sessionIdentity: review.sessionIdentity,
        );
        if (!canceled) return;
      } else if (!review.isBroadcasted) {
        final commands = ref.read(walletCommandsProvider);
        final prepared = transactionReviewPrepared(review);
        if (prepared == null) return;
        final canceled = await commands.cancelPreparedTransaction(
          transaction: prepared,
          sessionIdentity: transactionReviewSessionIdentity(review)!,
        );
        if (!canceled) return;
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
    HomeRoute().go(context);
  }
}
