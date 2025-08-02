import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/shared/widgets/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';

class BurnReviewContent extends ConsumerWidget {
  const BurnReviewContent(this.transaction, {super.key});

  final BurnTransaction transaction;

  bool get isXelisBurn => transaction.asset == AppResources.xelisHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.only(top: Spaces.medium),
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.asset,
                        style: context.bodyLarge!.copyWith(
                          color: context.moreColors.mutedColor,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),
                      isXelisBurn
                          ? Row(
                              children: [
                                Logo(
                                  imagePath:
                                      AppResources.greenBackgroundBlackIconPath,
                                ),
                                const SizedBox(width: Spaces.small),
                                Text(AppResources.xelisName),
                              ],
                            )
                          : Text(truncateText(transaction.asset)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.amount.capitalize(),
                        style: context.bodyLarge!.copyWith(
                          color: context.moreColors.mutedColor,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),
                      SelectableText(transaction.amount),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spaces.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.fee,
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              SelectableText(transaction.fee),
            ],
          ),
          const SizedBox(height: Spaces.small),
          Divider(),
          SizedBox(height: Spaces.small),
          Text(
            loc.hash,
            style: context.bodyLarge!.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transaction.txHash),
          const SizedBox(height: Spaces.large),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: AppDurations.animFast),
            child: transaction.isBroadcasted
                ? SizedBox.shrink()
                : FormBuilderCheckbox(
                    name: 'confirm',
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: Spaces.small),
                      isDense: true,
                      fillColor: Colors.transparent,
                    ),
                    title: Text(
                      loc.burn_confirmation,
                      style: context.bodyMedium,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                    onChanged: (value) {
                      ref
                          .read(transactionReviewProvider.notifier)
                          .setConfirmation(value as bool);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
