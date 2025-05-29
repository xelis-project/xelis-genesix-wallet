import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/components/tracked_asset_details.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class TrackedAssetItem extends ConsumerStatefulWidget {
  const TrackedAssetItem({required this.assetHash, super.key});

  final String assetHash;

  @override
  ConsumerState<TrackedAssetItem> createState() => _AssetItemWidgetState();
}

class _AssetItemWidgetState extends ConsumerState<TrackedAssetItem> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );
    final asset = knownAssets[widget.assetHash]!;
    final balance = balances[widget.assetHash]!;

    final isXelisAsset = widget.assetHash == sdk.xelisAsset;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spaces.medium,
          Spaces.small,
          Spaces.medium,
          Spaces.small,
        ),
        child: Row(
          children: [
            Row(
              children: [
                if (isXelisAsset) ...[
                  Container(
                    width: 35,
                    height: 35,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Image.asset(
                      AppResources.greenBackgroundBlackIconPath,
                      // fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: Spaces.medium),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      loc.name,
                      style: context.labelMedium?.copyWith(
                        color: context.moreColors.mutedColor,
                      ),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(asset.name, style: context.bodyLarge),
                  ],
                ),
              ],
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.balance,
                  style: context.labelMedium?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  '$balance ${asset.ticker}',
                  style: context.bodyLarge,
                ),
              ],
            ),
            const SizedBox(width: Spaces.small),
            Column(
              children: [
                IconButton(
                  onPressed: () => _showDetails(asset, balance),
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(sdk.AssetData asset, String balance) {
    showDialog<void>(
      context: context,
      builder: (context) => TrackedAssetDetails(
        hash: widget.assetHash,
        asset: asset,
        balance: balance,
      ),
    );
  }
}
