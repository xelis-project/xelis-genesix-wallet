import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class DeleteMultisigReviewContent extends ConsumerWidget {
  const DeleteMultisigReviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final transactionReview = ref.watch(transactionReviewProvider);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.hash,
            style: context.bodyLarge!
                .copyWith(color: context.moreColors.mutedColor),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transactionReview.finalHash!),
          const SizedBox(height: Spaces.small),
          Text(
            loc.fee,
            style: context.bodyLarge!
                .copyWith(color: context.moreColors.mutedColor),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transactionReview.fee!),
          const SizedBox(height: Spaces.small),
          Text(
            loc.transaction_type,
            style: context.bodyLarge!
                .copyWith(color: context.moreColors.mutedColor),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(loc.multisig_removal),
        ],
      ),
    );
  }
}
