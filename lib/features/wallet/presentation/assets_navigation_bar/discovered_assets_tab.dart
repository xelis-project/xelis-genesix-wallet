import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/components/discovered_asset_item.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class DiscoveredAssetsTab extends ConsumerWidget {
  const DiscoveredAssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );

    final discoveredAssets =
        knownAssets.keys.where((hash) => !balances.containsKey(hash)).toList();

    if (discoveredAssets.isEmpty) {
      return Center(
        child: Text(
          'No discovered assets',
          style: context.bodyLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: discoveredAssets.length,
        padding: const EdgeInsets.all(Spaces.large),
        itemBuilder: (BuildContext context, int index) {
          final hash = discoveredAssets[index];
          return DiscoveredAssetItem(hash);
        },
      );
    }
  }
}
