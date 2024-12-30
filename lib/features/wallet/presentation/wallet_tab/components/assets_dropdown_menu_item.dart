import 'package:flutter/material.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/logo.dart';

class AssetsDropdownMenuItem {
  static DropdownMenuItem<String> fromMapEntry(MapEntry<String, String> asset) {
    final isXelis = asset.key == AppResources.xelisAsset.hash;
    final xelisPath = AppResources.xelisAsset.imagePath!;
    return DropdownMenuItem<String>(
      value: asset.key,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isXelis
              ? Row(
                  children: [
                    Logo(
                      imagePath: xelisPath,
                    ),
                    const SizedBox(width: Spaces.small),
                    Text(AppResources.xelisAsset.name),
                  ],
                )
              : Text(truncateText(asset.key)),
          Text(asset.value),
        ],
      ),
    );
  }
}
