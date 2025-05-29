import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BurnEntryContent extends ConsumerWidget {
  const BurnEntryContent(this.burnEntry, {super.key});

  final BurnEntry burnEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    final isXelis = burnEntry.asset == xelisAsset;
    final xelisImagePath = AppResources.greenBackgroundBlackIconPath;

    String asset;
    String amount;
    if (knownAssets.containsKey(burnEntry.asset)) {
      final assetData = knownAssets[burnEntry.asset]!;
      asset = assetData.name;
      amount =
          '-${formatCoin(burnEntry.amount, assetData.decimals, assetData.ticker)}';
    } else {
      asset = truncateText(burnEntry.asset, maxLength: 20);
      amount = '-${burnEntry.amount.toString()}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.fee,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          formatXelis(burnEntry.fee, network),
          style: context.bodyLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spaces.medium,
              Spaces.small,
              Spaces.medium,
              Spaces.small,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spaces.extraSmall),
                      child: Text(
                        loc.asset,
                        style: context.labelMedium?.copyWith(
                          color: context.moreColors.mutedColor,
                        ),
                      ),
                    ),
                    isXelis
                        ? Row(
                            children: [
                              Logo(imagePath: xelisImagePath),
                              const SizedBox(width: Spaces.small),
                              Text(AppResources.xelisName),
                            ],
                          )
                        : SelectableText(asset),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spaces.extraSmall),
                      child: Text(
                        loc.amount,
                        style: context.labelMedium?.copyWith(
                          color: context.moreColors.mutedColor,
                        ),
                      ),
                    ),
                    SelectableText(amount),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
