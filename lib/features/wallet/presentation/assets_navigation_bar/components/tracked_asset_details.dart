import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class TrackedAssetDetails extends ConsumerWidget {
  const TrackedAssetDetails({
    required this.hash,
    required this.asset,
    this.balance,
    super.key,
  });

  final String hash;
  final sdk.AssetData asset;
  final String? balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final isXelisAsset = hash == sdk.xelisAsset;
    final xelisImagePath = AppResources.greenBackgroundBlackIconPath;

    return GenericDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  loc.details.capitalize(),
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.name.capitalize(),
            style: context.bodyLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          isXelisAsset
              ? Row(
                  children: [
                    Logo(imagePath: xelisImagePath),
                    const SizedBox(width: Spaces.small),
                    Text(AppResources.xelisName),
                  ],
                )
              : SelectableText(asset.name, style: context.bodyLarge),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.hash.capitalize(),
            style: context.bodyLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          Tooltip(
            message: hash,
            child: InkWell(
              child: Text(
                truncateText(hash, maxLength: 20),
                style: context.bodyLarge,
              ),
              onTap: () => copyToClipboard(hash, ref, loc.copied),
            ),
          ),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.decimals,
            style: context.bodyLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(asset.decimals.toString(), style: context.bodyLarge),
          if (asset.maxSupply != null) ...[
            const SizedBox(height: Spaces.medium),
            Text(
              loc.max_supply,
              style: context.bodyLarge?.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              formatCoin(asset.maxSupply!, asset.decimals, asset.ticker),
              style: context.bodyLarge,
            ),
          ],
          if (asset.owner != null) ...[
            const SizedBox(height: Spaces.medium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.contract,
                  style: context.bodyLarge?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(width: Spaces.extraSmall),
                SelectableText(asset.owner!.contract, style: context.bodyLarge),
                const SizedBox(height: Spaces.medium),
                Text(
                  loc.id,
                  style: context.bodyLarge?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  asset.owner!.id.toString(),
                  style: context.bodyLarge,
                ),
              ],
            ),
          ],
          if (balance != null) ...[
            const SizedBox(height: Spaces.medium),
            Text(
              loc.balance.capitalize(),
              style: context.bodyLarge?.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              '${balance!} ${asset.ticker}',
              style: context.bodyLarge,
            ),
          ],
          if (!isXelisAsset) ...[
            const SizedBox(height: Spaces.extraLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(Spaces.medium),
                      side: BorderSide(color: context.colors.error, width: 2),
                    ),
                    onPressed: () {
                      ref.read(walletStateProvider.notifier).untrackAsset(hash);
                      context.pop();
                    },
                    child: Text(loc.untrack, style: context.bodyMedium),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
