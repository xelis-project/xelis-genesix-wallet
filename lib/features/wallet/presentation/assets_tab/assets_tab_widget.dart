import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/domain/asset.dart';
import 'package:genesix/features/wallet/presentation/assets_tab/asset_item_widget.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';

class AssetsTab extends ConsumerWidget {
  const AssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final loc = ref.watch(appLocalizationsProvider);

    List<Asset> assets = [AppResources.xelisAsset];

    return ListView.builder(
      itemCount: assets.length,
      padding: const EdgeInsets.all(Spaces.large),
      itemBuilder: (BuildContext context, int index) {
        final asset = assets[index];
        return AssetItemWidget(asset: asset);
      },
    );
  }
}
