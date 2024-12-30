import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/asset.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:transparent_image/transparent_image.dart';

class AssetItemWidget extends ConsumerStatefulWidget {
  const AssetItemWidget({required this.asset, super.key});

  final Asset asset;

  @override
  ConsumerState<AssetItemWidget> createState() => _AssetItemWidgetState();
}

class _AssetItemWidgetState extends ConsumerState<AssetItemWidget> {
  @override
  Widget build(BuildContext context) {
    // final loc = ref.watch(appLocalizationsProvider);

    final walletSnapshot = ref.read(walletStateProvider);
    var assets = walletSnapshot.assets;
    var balance = assets[widget.asset.hash] ?? AppResources.zeroBalance;

    Widget logo;
    if (widget.asset.isNetworkImage) {
      String url = widget.asset.imageURL!;
      // final networkImage = NetworkImage(url);
      // precacheImage(networkImage, context);

      // TODO: Cache image in memory
      // https://pub.dev/packages/cached_network_image
      logo = FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          image: NetworkImage(url));
    } else {
      logo = Image.asset(
        widget.asset.imagePath!,
        fit: BoxFit.cover,
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spaces.medium, Spaces.small, Spaces.medium, Spaces.small),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: logo,
                ),
                const SizedBox(width: Spaces.medium),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      widget.asset.name,
                      style: context.bodyLarge,
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(
                      widget.asset.ticker,
                      style: context.bodyMedium!
                          .copyWith(color: context.moreColors.mutedColor),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SelectableText(
                  balance,
                  style: context.bodyLarge,
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  truncateText(widget.asset.hash),
                  style: context.bodyMedium!
                      .copyWith(color: context.moreColors.mutedColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
