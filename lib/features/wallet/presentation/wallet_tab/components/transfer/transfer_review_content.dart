import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class TransferReviewContentWidget extends ConsumerStatefulWidget {
  const TransferReviewContentWidget({super.key});

  @override
  ConsumerState createState() => _TransferReviewWidgetState();
}

class _TransferReviewWidgetState
    extends ConsumerState<TransferReviewContentWidget> {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                const SizedBox(width: Spaces.extraSmall),
                                Text(
                                  AppResources.xelisAsset.name,
                                  style: context.bodyLarge,
                                ),
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
                        future: transactionReview.amount!,
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
              Text(
                loc.fee,
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor),
              ),
              SelectableText(transactionReview.fee!),
            ],
          ),
          const SizedBox(height: Spaces.small),
          Divider(),
          const SizedBox(height: Spaces.small),
          Text(loc.hash,
              style: context.bodyLarge!
                  .copyWith(color: context.moreColors.mutedColor)),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transactionReview.finalHash!),
          const SizedBox(height: Spaces.small),
          if (transactionReview.walletAddress!.isIntegrated) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(loc.destination,
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor)),
                const SizedBox(width: Spaces.small),
                Tooltip(
                  message: loc.integrated_address_detected,
                  textStyle: context.bodyMedium
                      ?.copyWith(color: context.colors.primary),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: context.moreColors.mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(transactionReview.destination!),
            const SizedBox(height: Spaces.small),
          ],
          Text(loc.receiver,
              style: context.bodyLarge!
                  .copyWith(color: context.moreColors.mutedColor)),
          const SizedBox(height: Spaces.extraSmall),
          Row(
            children: [
              HashiconWidget(
                hash: transactionReview.walletAddress!.address,
                size: const Size(35, 35),
              ),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: SelectableText(transactionReview.walletAddress!.address),
              ),
            ],
          ),
          if (transactionReview.walletAddress!.isIntegrated) ...[
            const SizedBox(height: Spaces.small),
            Text(loc.payment_id,
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(transactionReview.walletAddress!.data.toString()),
          ],
        ],
      ),
    );
  }
}
