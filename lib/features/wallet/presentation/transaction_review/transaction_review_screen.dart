import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
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
  final _sharesFormKey = GlobalKey<FormState>();
  final List<TextEditingController> _shareControllers = [];
  bool _isFinalizing = false;
  bool _isBroadcasting = false;
  bool _isClosing = false;

  @override
  void dispose() {
    for (final controller in _shareControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final review = ref.watch(transactionReviewProvider);
    final busy = _isFinalizing || _isBroadcasting || _isClosing;

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
                  child: _buildContent(context, review),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransactionReviewState review) {
    if (review.isBroadcasted) return _BroadcastComplete(onClose: _finish);

    return switch (review) {
      SignaturePending() => _buildSignatureCollection(context, review),
      SingleTransferTransaction() ||
      BurnTransaction() ||
      DeleteMultisigTransaction() => _buildBroadcastReview(context, review),
      Initial() => _EmptyReview(onClose: _finish),
    };
  }

  Widget _buildSignatureCollection(
    BuildContext context,
    SignaturePending review,
  ) {
    final loc = ref.watch(appLocalizationsProvider);
    final request = review.request;
    _ensureShareInputs(request.threshold);

    return Column(
      key: ValueKey('signature-${request.hash}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.small,
          children: [
            Text(
              loc.multisig_signing_request,
              style: context.theme.typography.display.xl2,
            ),
            Text(
              loc.multisig_barrier_message,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
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
                        loc.multisig_signing_request,
                        style: context.theme.typography.display.lg,
                      ),
                    ),
                    FButton.icon(
                      variant: .ghost,
                      semanticsLabel: loc.copy,
                      onPress: () =>
                          copyToClipboard(request.encoded, ref, loc.copied),
                      child: const Icon(FLucideIcons.copy, size: 18),
                    ),
                  ],
                ),
                const FDivider(),
                _Detail(label: loc.wallet, value: request.source),
                _Detail(label: loc.network, value: request.network),
                _Detail(label: loc.hash, value: request.hash),
                _Detail(
                  label: loc.threshold,
                  value: '${request.threshold}/${request.participants.length}',
                ),
              ],
            ),
          ),
        ),
        Form(
          key: _sharesFormKey,
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.medium,
                children: [
                  Text(
                    loc.signature_share,
                    style: context.theme.typography.display.lg,
                  ),
                  ...List.generate(
                    request.threshold,
                    (index) => FTextFormField(
                      control: .managed(controller: _shareControllers[index]),
                      autocorrect: false,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          _maxMultisigSignatureShareLength,
                        ),
                      ],
                      minLines: 3,
                      maxLines: 6,
                      label: Text('#${index + 1}'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? loc.field_required_error
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AsyncFButton(
            isLoading: _isFinalizing,
            onPress: _isFinalizing ? null : _finalize,
            prefix: const Icon(FLucideIcons.arrowRight, size: 18),
            child: Text(loc.next),
          ),
        ),
      ],
    );
  }

  Widget _buildBroadcastReview(
    BuildContext context,
    TransactionReviewState review,
  ) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      key: ValueKey('broadcast-${_transactionHash(review)}'),
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
          label: Text(_confirmationLabel(review)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AsyncFButton(
            isLoading: _isBroadcasting,
            onPress: !review.isConfirmed || _isBroadcasting
                ? null
                : () => startWithBiometricAuth(
                    ref,
                    callback: _broadcast,
                    reason: loc.please_authenticate_tx,
                  ),
            prefix: const Icon(FLucideIcons.send, size: 18),
            child: Text(loc.broadcast),
          ),
        ),
      ],
    );
  }

  String _confirmationLabel(TransactionReviewState review) {
    final loc = ref.read(appLocalizationsProvider);
    return switch (review) {
      BurnTransaction() => loc.burn_confirmation,
      DeleteMultisigTransaction() => loc.delete_multisig_confirmation,
      _ => loc.transaction_broadcast_confirmation,
    };
  }

  Future<void> _finalize() async {
    if (_isFinalizing || !(_sharesFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final review = ref.read(transactionReviewProvider);
    if (review is! SignaturePending) return;
    final commands = ref.read(walletCommandsProvider);

    setState(() => _isFinalizing = true);
    try {
      final transaction = await commands.finalizeMultisigTransaction(
        txHash: review.request.hash,
        signatureShares: _shareControllers
            .take(review.request.threshold)
            .map((controller) => controller.text.trim())
            .toList(growable: false),
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
      if (!mounted || !broadcasted) return;
      ref.read(transactionReviewProvider.notifier).broadcast();
      if (review is DeleteMultisigTransaction) {
        ref.read(multisigPendingStateProvider.notifier).pendingState();
      }
      ref
          .read(toastProvider.notifier)
          .showEvent(
            description: ref
                .read(appLocalizationsProvider)
                .transaction_broadcast_message,
          );
    } on AnyhowException {
      talker.error('Cannot broadcast transaction');
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .showError(description: ref.read(appLocalizationsProvider).oups);
      }
    } catch (_) {
      talker.error('Cannot broadcast transaction');
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .showError(description: ref.read(appLocalizationsProvider).oups);
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

  void _ensureShareInputs(int threshold) {
    while (_shareControllers.length < threshold) {
      _shareControllers.add(TextEditingController());
    }
    while (_shareControllers.length > threshold) {
      _shareControllers.removeLast().dispose();
    }
  }

  String? _transactionHash(TransactionReviewState review) => switch (review) {
    SingleTransferTransaction(:final txHash) ||
    BurnTransaction(:final txHash) ||
    DeleteMultisigTransaction(:final txHash) => txHash,
    _ => null,
  };
}

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
