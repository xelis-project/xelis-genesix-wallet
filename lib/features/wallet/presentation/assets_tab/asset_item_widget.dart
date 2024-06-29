import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_screen.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';

class Asset {
  final String hash;
  final String name;
  final String img;
  final int decimals;
  final String ticker;

  const Asset({
    required this.hash,
    required this.name,
    required this.img,
    required this.decimals,
    required this.ticker,
  });
}

class AssetItemWidget extends ConsumerStatefulWidget {
  const AssetItemWidget({required this.asset, super.key});

  final Asset asset;

  @override
  ConsumerState<AssetItemWidget> createState() => _AssetItemWidgetState();
}

class _AssetItemWidgetState extends ConsumerState<AssetItemWidget> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final walletSnapshot = ref.read(walletStateProvider);
    var assets = walletSnapshot.assets ?? {};
    var balanceAtomic = assets[widget.asset.hash] ?? 0;
    var balance = balanceAtomic / pow(10, widget.asset.decimals);

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
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: Image.network(
                        widget.asset.img,
                      ).image,
                    ),
                  ),
                  width: 40,
                  height: 40,
                ),
                const SizedBox(
                  width: Spaces.medium,
                ),
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
                  balance.toStringAsFixed(widget.asset.decimals),
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
