import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/components/discovered_asset_details.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class DiscoveredAssetItem extends ConsumerStatefulWidget {
  const DiscoveredAssetItem(this.assetHash, {super.key});

  final String assetHash;

  @override
  ConsumerState<DiscoveredAssetItem> createState() =>
      _DiscoveredAssetItemState();
}

class _DiscoveredAssetItemState extends ConsumerState<DiscoveredAssetItem> {
  @override
  Widget build(BuildContext context) {
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final assetData = knownAssets[widget.assetHash]!;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(assetData.name, style: context.bodyLarge),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(
                      assetData.ticker,
                      style: context.bodyMedium!.copyWith(
                        color: context.moreColors.mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SelectableText('Ticker', style: context.bodyLarge),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  truncateText(assetData.ticker),
                  style: context.bodyMedium!.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: Spaces.small),
            Column(
              children: [
                IconButton(
                  onPressed: () => _trackAsset(widget.assetHash, assetData),
                  icon: const Icon(Icons.add),
                  tooltip: 'Track this asset',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _trackAsset(String hash, AssetData asset) {
    showDialog<void>(
      context: context,
      builder: (context) => DiscoveredAssetDetails(hash, asset),
    );
  }
}
