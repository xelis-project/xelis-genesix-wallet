import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_sheet.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';

class BroadcastReviewStep extends ConsumerWidget {
  const BroadcastReviewStep({
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
          LabeledValue.text(loc.transaction_type, loc.transfer),
          LabeledValue.text(loc.asset, transaction.name),
          LabeledValue.text(loc.amount, transaction.amount),
          LabeledValue.text(loc.fee, transaction.fee),
          LabeledValue.text(loc.hash, transaction.txHash),
          LabeledValue.child(
            loc.receiver,
            AddressWidget(transaction.destinationAddress.address),
          ),
          if (transaction.hasAttachedData)
            _AttachedDataReview(transaction: transaction),
        ],
        BurnTransaction transaction => [
          LabeledValue.text(loc.transaction_type, loc.burn),
          LabeledValue.text(
            loc.asset,
            transaction.name.isEmpty ? transaction.asset : transaction.name,
          ),
          LabeledValue.text(loc.amount, transaction.amount),
          LabeledValue.text(loc.fee, transaction.fee),
          LabeledValue.text(loc.hash, transaction.txHash),
        ],
        DeleteMultisigTransaction transaction => [
          LabeledValue.text(loc.transaction_type, loc.multisig_removal),
          LabeledValue.text(loc.fee, transaction.fee),
          LabeledValue.text(loc.hash, transaction.txHash),
        ],
        _ => const [],
      },
    );
  }
}

class _AttachedDataReview extends ConsumerStatefulWidget {
  const _AttachedDataReview({required this.transaction});

  final SingleTransferTransaction transaction;

  @override
  ConsumerState<_AttachedDataReview> createState() =>
      _AttachedDataReviewState();
}

class _AttachedDataReviewState extends ConsumerState<_AttachedDataReview> {
  bool _isInspecting = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return LabeledValue.child(
      loc.attached_data,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spaces.small,
        children: [
          Text(switch (widget.transaction.attachedDataEncrypted) {
            true => loc.attached_data_encrypted,
            false => loc.attached_data_not_encrypted,
            null => loc.attached_data_included,
          }),
          AsyncFButton(
            key: const ValueKey('view-attached-data'),
            isLoading: _isInspecting,
            onPress: _isInspecting ? null : _inspectPreparedExtraData,
            variant: .outline,
            size: .sm,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(FLucideIcons.eye, size: 16),
            child: Text(loc.view_attached_data),
          ),
        ],
      ),
    );
  }

  Future<void> _inspectPreparedExtraData() async {
    if (_isInspecting) return;

    final prepared = widget.transaction.prepared;

    setState(() => _isInspecting = true);

    try {
      final repository = ref.read(activeWalletRepositoryProvider);
      if (repository == null ||
          !identical(repository, widget.transaction.sessionIdentity)) {
        throw StateError('No active wallet repository');
      }

      final revealed = await repository.inspectPreparedTransferExtraData(
        prepared,
        transferIndex: 0,
      );

      if (!mounted) return;
      setState(() => _isInspecting = false);
      if (!identical(widget.transaction.prepared, prepared) ||
          !identical(
            ref.read(activeWalletRepositoryProvider),
            widget.transaction.sessionIdentity,
          )) {
        return;
      }

      showFSheet<void>(
        context: context,
        side: FLayout.btt,
        useRootNavigator: true,
        mainAxisMaxRatio: context.responsiveSheetMaxRatio,
        builder: (context) => ExtraDataSheet.typed(
          data: revealed.data,
          source: revealed.source,
          encrypted: revealed.encrypted,
        ),
      );
    } catch (error, stackTrace) {
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.transaction.prepared.inspect',
        applicationCode: 'wallet_prepared_transaction_inspect_failed',
      );

      if (!mounted) return;
      setState(() => _isInspecting = false);
      if (!identical(widget.transaction.prepared, prepared)) return;

      ref
          .read(toastProvider.notifier)
          .showFailure(
            title: ref.read(appLocalizationsProvider).attached_data,
            failure: failure,
          );
    }
  }
}
