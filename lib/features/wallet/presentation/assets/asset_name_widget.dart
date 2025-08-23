import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/logo.dart';

class AssetNameWidget extends StatelessWidget {
  const AssetNameWidget({
    super.key,
    required this.assetName,
    required this.isXelis,
  });

  final String assetName;
  final bool isXelis;
  final xelisImagePath = AppResources.greenBackgroundBlackIconPath;

  @override
  Widget build(BuildContext context) {
    return isXelis
        ? Row(
            children: [
              Logo(imagePath: xelisImagePath),
              const SizedBox(width: Spaces.small),
              Text(
                AppResources.xelisName,
                style: context.theme.typography.base,
              ),
            ],
          )
        : SelectableText(assetName, style: context.theme.typography.base);
  }
}
