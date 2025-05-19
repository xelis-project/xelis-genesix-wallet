import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
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
    final loc = ref.watch(appLocalizationsProvider);
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      loc.name,
                      style: context.bodyMedium!.copyWith(
                        color: context.moreColors.mutedColor,
                      ),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(assetData.name, style: context.bodyLarge),
                  ],
                ),
              ],
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.ticker.toLowerCase(),
                  style: context.bodyMedium!.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(assetData.ticker, style: context.bodyLarge),
              ],
            ),
            const SizedBox(width: Spaces.small),
            Column(
              children: [
                IconButton(
                  onPressed: () => _trackAsset(widget.assetHash, assetData),
                  icon: const Icon(Icons.add),
                  tooltip: loc.track_button_tooltip,
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
