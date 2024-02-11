import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class AssetsTab extends ConsumerWidget {
  const AssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        'ASSETS TAB',
        style: context.displayMedium,
      ),
    );
    // final asyncData = ref.watch(walletAssetsProvider);
    // return asyncData.when(
    //   skipLoadingOnReload: true,
    //   data: (assets) {
    //     return ListView.builder(
    //       itemCount: assets.length,
    //       itemBuilder: (context, index) {
    //         return AssetRow(
    //           asset: assets[index],
    //         );
    //       },
    //     );
    //   },
    //   error: (error, stackTrace) => Center(child: Text(error.toString())),
    //   loading: () => Center(
    //     child: LoadingAnimationWidget.waveDots(
    //       color: context.colors.primary,
    //       size: 20,
    //     ),
    //   ),
    // );
  }
}
