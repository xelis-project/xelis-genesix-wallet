import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/widgets/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';

class TransferReviewContentWidget extends ConsumerWidget {
  const TransferReviewContentWidget(this.transaction, {super.key});

  final SingleTransferTransaction transaction;

  bool get isXelisTransfer => transaction.asset == AppResources.xelisHash;

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.asset,
                        style: context.theme.typography.base.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),
                      isXelisTransfer
                          ? Row(
                              children: [
                                Logo(
                                  imagePath:
                                      AppResources.greenBackgroundBlackIconPath,
                                ),
                                const SizedBox(width: Spaces.extraSmall),
                                Text(
                                  transaction.name,
                                  style: context.theme.typography.base,
                                ),
                              ],
                            )
                          : Text(truncateText(transaction.name)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.amount.capitalize(),
                        style: context.theme.typography.base.copyWith(
                          color: context.theme.colors.mutedForeground,
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
                style: context.theme.typography.base.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              SelectableText(transaction.fee),
            ],
          ),
          const SizedBox(height: Spaces.small),
          Divider(),
          const SizedBox(height: Spaces.small),
          Text(
            loc.hash,
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(transaction.txHash),
          const SizedBox(height: Spaces.small),
          if (transaction.destinationAddress.isIntegrated) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  loc.destination,
                  style: context.theme.typography.base.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: Spaces.small),
                Tooltip(
                  message: loc.integrated_address_detected,
                  textStyle: context.bodyMedium?.copyWith(
                    color: context.colors.primary,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(transaction.destination),
            const SizedBox(height: Spaces.small),
          ],
          Text(
            loc.receiver,
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          AddressWidget(transaction.destinationAddress.address),
          if (transaction.destinationAddress.isIntegrated) ...[
            const SizedBox(height: Spaces.small),
            Text(
              loc.payment_id,
              style: context.theme.typography.base..copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(transaction.destinationAddress.data.toString()),
          ],
        ],
      ),
    );
  }
}
