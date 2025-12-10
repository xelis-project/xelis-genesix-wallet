import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/logo.dart';

class TransferReviewContentWidget extends ConsumerWidget {
  const TransferReviewContentWidget(
    this.style,
    this.animation, {
    super.key,
    required this.transaction,
    required this.onConfirm,
    this.onCancel,
  });

  final SingleTransferTransaction transaction;
  final FDialogStyle style;
  final Animation<double> animation;

  /// Called when user taps confirm.
  final VoidCallback onConfirm;

  /// Optional cancel handler; defaults to Navigator.pop.
  final VoidCallback? onCancel;

  bool get isXelisTransfer => transaction.asset == AppResources.xelisHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return FDialog(
      style: style,
      animation: animation,
      constraints: const BoxConstraints(maxWidth: 600),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset + Amount card
          Padding(
            padding: const EdgeInsets.only(top: Spaces.small),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(Spaces.extraSmall),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Asset info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.asset,
                          style: context.bodyLarge!.copyWith(
                            color: FTheme.of(context).colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: Spaces.small),
                        isXelisTransfer
                          ? Row(
                              children: [
                                Logo(
                                  imagePath: AppResources
                                      .greenBackgroundBlackIconPath,
                                ),
                                const SizedBox(width: Spaces.extraSmall),
                                Text(
                                  transaction.name,
                                  style: context.bodyLarge,
                                ),
                              ],
                            )
                          : Text(truncateText(transaction.name)),
                      ],
                    ),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.amount.capitalize(),
                          style: context.bodyLarge!.copyWith(
                            color: FTheme.of(context).colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: Spaces.small),
                        SelectableText(
                          transaction.amount,
                          style: TextStyle(
                            color: FTheme.of(context).colors.foreground,
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: Spaces.large),

          // Fee row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.fee,
                style: context.bodyLarge!.copyWith(
                  color: FTheme.of(context).colors.mutedForeground,
                ),
              ),
              SelectableText(
                transaction.fee,
                style: TextStyle(
                  color: FTheme.of(context).colors.foreground,
                )
              ),
            ],
          ),
          const SizedBox(height: Spaces.medium),

          FDivider(
            style: FDividerStyle(
              padding: const EdgeInsets.symmetric(
                vertical: Spaces.small,
              ),
              color: FTheme.of(context).colors.primary,
              width: 1,
            ),
          ),
          const SizedBox(height: Spaces.medium),

          // Hash
          Text(
            loc.hash,
            style: context.bodyLarge!.copyWith(
              color: FTheme.of(context).colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            transaction.txHash,
            style: TextStyle(
              color: FTheme.of(context).colors.foreground,
            ),
          ),
          const SizedBox(height: Spaces.medium),

          // Integrated destination (if applicable)
          if (transaction.destinationAddress.isIntegrated) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  loc.destination,
                  style: context.bodyLarge!.copyWith(
                    color: FTheme.of(context).colors.mutedForeground,
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
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              transaction.destination,
              style: TextStyle(
                color: FTheme.of(context).colors.foreground,
              ),
            ),
            const SizedBox(height: Spaces.medium),
          ],

          // Receiver
          Text(
            loc.receiver,
            style: context.bodyLarge!.copyWith(
              color: FTheme.of(context).colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          AddressWidget(transaction.destinationAddress.address),
          const SizedBox(height: Spaces.medium),

          // Payment ID for integrated address
          if (transaction.destinationAddress.isIntegrated) ...[
            Text(
              loc.payment_id,
              style: context.bodyLarge!.copyWith(
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              transaction.destinationAddress.data.toString(),
              style: TextStyle(
                color: FTheme.of(context).colors.primary,
              ),
            ),
            const SizedBox(height: Spaces.medium),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: onCancel ?? () => Navigator.of(context).pop(),
                  child: Text(loc.cancel_button),
                ),
              ),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: FButton(
                  style: FButtonStyle.primary(),
                  onPress: onConfirm,
                  child: Text(loc.confirm_button),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
