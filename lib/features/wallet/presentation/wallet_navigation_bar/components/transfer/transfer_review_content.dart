import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:forui/theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/logo.dart';

class TransferReviewContentWidget extends ConsumerWidget {
  const TransferReviewContentWidget(this.transaction, {super.key});

  final SingleTransferTransaction transaction;

  bool get isXelisTransfer => transaction.asset == AppResources.xelisHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final muted = context.theme.colors.mutedForeground;

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
                  // Asset column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.asset,
                        style: context.theme.typography.base.copyWith(
                          color: muted,
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

                  // Amount column (FIXED)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.amount.capitalize(),
                        style: context.theme.typography.base.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),
                      SelectableText(
                        transaction.amount,
                        style: TextStyle(
                          color: context.theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spaces.medium),

          // Fee row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.fee,
                style: context.bodyLarge!.copyWith(color: muted),
              ),
              SelectableText(
                transaction.fee,
                style: TextStyle(
                  color: context.theme.colors.foreground,
                ),
              ),
            ],
          ),

          FDivider(
            style: FDividerStyle(
              padding: const EdgeInsets.symmetric(vertical: Spaces.small),
              color: FTheme.of(context).colors.primary,
              width: 1,
            ),
          ),

          // Hash
          Text(
            loc.hash,
            style: context.bodyLarge!.copyWith(color: muted),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            transaction.txHash,
            style: TextStyle(
              color: context.theme.colors.primary,
            ),
          ),
          const SizedBox(height: Spaces.small),

          // Integrated address extra info
          if (transaction.destinationAddress.isIntegrated) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  loc.destination,
                  style: context.bodyLarge!.copyWith(color: muted),
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
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(transaction.destination),
            const SizedBox(height: Spaces.small),
          ],

          const SizedBox(height: Spaces.small),

          // Receiver
          Text(
            loc.receiver,
            style: context.theme.typography.base.copyWith(
              color: muted,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          AddressWidget(transaction.destinationAddress.address),

          if (transaction.destinationAddress.isIntegrated) ...[
            const SizedBox(height: Spaces.small),
            Text(
              loc.payment_id,
              style: context.theme.typography.base.copyWith( // FIXED
                color: muted,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              transaction.destinationAddress.data.toString(),
            ),
          ],

          const SizedBox(height: Spaces.small),
        ],
      ),
    );
  }
}
