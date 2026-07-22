import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
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
          if (transaction.destinationAddress.isIntegrated)
            LabeledValue.text(
              loc.payment_id,
              transaction.destinationAddress.data.toString(),
            ),
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
