import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class DeleteMultisigReviewContent extends ConsumerWidget {
  const DeleteMultisigReviewContent(this.transaction, {super.key});

  final DeleteMultisigTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.hash,
            style: context.bodyLarge!.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transaction.txHash),
          const SizedBox(height: Spaces.small),
          Text(
            loc.fee,
            style: context.bodyLarge!.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transaction.fee),
          const SizedBox(height: Spaces.small),
          Text(
            loc.transaction_type,
            style: context.bodyLarge!.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(loc.multisig_removal),
        ],
      ),
    );
  }
}
