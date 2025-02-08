import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';

class BurnReviewContent extends ConsumerStatefulWidget {
  const BurnReviewContent({super.key});

  @override
  ConsumerState createState() => _BurnReviewContentState();
}

class _BurnReviewContentState extends ConsumerState<BurnReviewContent> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final transactionReview = ref.watch(transactionReviewProvider);
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
                      Text(loc.asset,
                          style: context.bodyLarge!
                              .copyWith(color: context.moreColors.mutedColor)),
                      const SizedBox(height: Spaces.small),
                      transactionReview.isXelisTransfer
                          ? Row(
                              children: [
                                Logo(
                                  imagePath: AppResources.xelisAsset.imagePath!,
                                ),
                                const SizedBox(width: Spaces.small),
                                Text(AppResources.xelisAsset.name),
                              ],
                            )
                          : Text(truncateText(transactionReview.asset!)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.amount.capitalize(),
                          style: context.bodyLarge!
                              .copyWith(color: context.moreColors.mutedColor)),
                      const SizedBox(height: Spaces.small),
                      FutureBuilder(
                        future: transactionReview.amount,
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          if (snapshot.hasData) {
                            return SelectableText(snapshot.data!);
                          } else {
                            return Text('...');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spaces.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.fee,
                  style: context.bodyLarge!
                      .copyWith(color: context.moreColors.mutedColor)),
              SelectableText(transactionReview.fee!),
            ],
          ),
          const SizedBox(height: Spaces.small),
          Divider(),
          SizedBox(height: Spaces.small),
          Text(loc.hash,
              style: context.bodyLarge!
                  .copyWith(color: context.moreColors.mutedColor)),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transactionReview.finalHash!),
          const SizedBox(height: Spaces.large),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: AppDurations.animFast),
            child: transactionReview.isBroadcast
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
                        errorText: loc.field_required_error),
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
