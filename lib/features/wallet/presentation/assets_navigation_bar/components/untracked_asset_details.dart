import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';

class UntrackedAssetDetails extends ConsumerWidget {
  const UntrackedAssetDetails(this.assetHash, this.assetData, {super.key});

  final String assetHash;
  final AssetData assetData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

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
            loc.track_asset_dialog_message,
            style: context.bodyMedium?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.small),
          Divider(),
          Text(
            loc.name.capitalize(),
            style: context.bodyLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(assetData.name, style: context.bodyLarge),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.ticker,
            style: context.bodyLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(assetData.ticker, style: context.bodyLarge),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.hash.capitalize(),
            style: context.bodyLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          Tooltip(
            message: assetHash,
            child: InkWell(
              child: Text(
                truncateText(assetHash, maxLength: 20),
                style: context.bodyLarge,
              ),
              onTap: () => copyToClipboard(assetHash, ref, loc.copied),
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
          SelectableText(
            assetData.decimals.toString(),
            style: context.bodyLarge,
          ),
          if (assetData.maxSupply != null) ...[
            const SizedBox(height: Spaces.medium),
            Text(
              loc.max_supply,
              style: context.bodyLarge?.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              formatCoin(
                assetData.maxSupply!,
                assetData.decimals,
                assetData.ticker,
              ),
              style: context.bodyLarge,
            ),
          ],
          if (assetData.owner != null) ...[
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
                SelectableText(
                  assetData.owner!.contract,
                  style: context.bodyLarge,
                ),
                const SizedBox(height: Spaces.medium),
                Text(
                  loc.id,
                  style: context.bodyLarge?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  assetData.owner!.id.toString(),
                  style: context.bodyLarge,
                ),
              ],
            ),
          ],
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
                    ref
                        .read(walletStateProvider.notifier)
                        .trackAsset(assetHash);
                    context.pop();
                  },
                  child: Text(loc.track, style: context.bodyMedium),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
