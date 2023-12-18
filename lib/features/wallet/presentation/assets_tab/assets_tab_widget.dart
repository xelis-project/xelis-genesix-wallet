import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/assets_tab/asset_entry_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class AssetsTab extends ConsumerWidget {
  const AssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(walletAssetsProvider);
    return asyncData.when(
      skipLoadingOnReload: true,
      data: (assets) {
        return ListView.builder(
          itemCount: assets.length,
          itemBuilder: (context, index) {
            return AssetRow(
              asset: assets[index],
            );
          },
        );
      },
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      loading: () => Center(
        child: LoadingAnimationWidget.waveDots(
          color: context.colors.primary,
          size: 20,
        ),
      ),
    );
  }
}
