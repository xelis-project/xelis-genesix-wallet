import 'package:flutter/material.dart';
import 'package:genesix/shared/widgets/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class AssetDropdownMenuItem {
  static DropdownMenuItem<String> fromMapEntry(
    MapEntry<String, String> balanceEntry,
    AssetData assetData, {
    bool showBalance = true,
  }) {
    final isXelisAsset = balanceEntry.key == AppResources.xelisHash;
    final xelisImagePath = AppResources.greenBackgroundBlackIconPath;

    final assetName = assetData.name;
    final assetTicker = assetData.ticker;

    return DropdownMenuItem<String>(
      value: balanceEntry.key,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isXelisAsset
              ? Row(
                  children: [
                    Logo(imagePath: xelisImagePath),
                    const SizedBox(width: Spaces.small),
                    Text(assetName),
                  ],
                )
              : Text(truncateText(assetName)),
          if (showBalance) Text('${balanceEntry.value} $assetTicker'),
        ],
      ),
    );
  }
}
