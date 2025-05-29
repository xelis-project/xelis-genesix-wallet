import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/components/untracked_asset_item.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class UntrackedAssetsTab extends ConsumerWidget {
  const UntrackedAssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );

    final untrackedAssets = knownAssets.keys
        .where((hash) => !balances.containsKey(hash))
        .toList();

    if (untrackedAssets.isEmpty) {
      return Center(
        child: Text(
          loc.no_untracked_assets,
          style: context.bodyLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: untrackedAssets.length,
        padding: const EdgeInsets.all(Spaces.large),
        itemBuilder: (BuildContext context, int index) {
          final hash = untrackedAssets[index];
          return UntrackedAssetItem(hash);
        },
      );
    }
  }
}
