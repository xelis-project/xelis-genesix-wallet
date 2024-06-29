import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_tab/asset_item_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class AssetsTab extends ConsumerWidget {
  const AssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    var xelisAsset = const Asset(
      hash: sdk.xelisAsset,
      decimals: 8,
      img: "https://raw.githubusercontent.com/xelis-project/xelis-assets/master/icons/png/circle/green_background_black_logo.png",
      name: "Xelis",
      ticker: "XEL",
    );

    List<Asset> assets = [xelisAsset];

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
