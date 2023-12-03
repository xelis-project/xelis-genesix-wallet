import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class AssetRow extends ConsumerWidget {
  const AssetRow({super.key, required this.asset});

  final AssetEntry asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(walletAssetLastBalanceProvider(hash: asset.hash!));
    var name = asset.hash;

    return data.when(
      skipLoadingOnReload: true,
      data: (versionedBalance) {
        var balance = versionedBalance.balance!.toDouble();
        if (asset.hash == xelisAsset) {
          name = 'XELIS';
          balance = versionedBalance.balance! / pow(10, 5);
        }
        return Card(
          child: ListTile(
            title: Text(
              name ?? '/',
              style: context.bodyLarge,
            ),
            subtitle: Text(
              'Balance: $balance',
              style: context.bodyLarge,
            ),
          ),
        );
      },
      error: (error, stackTrace) => Card(
        child: ListTile(
          title: Text(name ?? '/'),
          subtitle: Text('Balance: $error'),
        ),
      ),
      loading: () => LoadingAnimationWidget.waveDots(
        color: context.colors.primary,
        size: 20,
      ),
    );
  }
}
