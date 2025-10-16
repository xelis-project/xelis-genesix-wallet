import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/xelis_price_provider.dart';
import 'package:genesix/features/wallet/presentation/home/xelis_price_sparkline.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_skeletonizer.dart';

class UsdBalanceWidget extends ConsumerStatefulWidget {
  const UsdBalanceWidget(this.xelisBalance, {super.key});

  final double xelisBalance;

  @override
  ConsumerState createState() => _UsdBalanceWidgetState();
}

class _UsdBalanceWidgetState extends ConsumerState<UsdBalanceWidget> {
  final String hidden = '********';

  @override
  Widget build(BuildContext context) {
    final hideBalance = ref.watch(
      settingsProvider.select((state) => state.hideBalance),
    );
    final xelisCoingeckoResponse = ref.watch(xelisPriceProvider).valueOrNull;

    if (hideBalance) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: Spaces.medium,
        children: [
          Text(
            hidden,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          Text(
            hidden,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (xelisCoingeckoResponse != null) {
      final response = xelisCoingeckoResponse;
      final xelisPrice = response.price.usd;
      final usdtBalance = xelisPrice * widget.xelisBalance;
      var displayedUSDBalance = formatUsd(usdtBalance);

      final percentChange24h = response.price.usd24hChange;
      final isPositiveChange = percentChange24h >= 0;
      var displayedPercentChange24h =
          '${percentChange24h.abs().toStringAsFixed(2)}%';

      final priceHistory24h = response.pricePoints.map((e) => e.price).toList();
      final sparklineColor = isPositiveChange
          ? context.theme.colors.upColor
          : context.theme.colors.downColor;

      final loc = ref.watch(appLocalizationsProvider);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: Spaces.medium,
        children: [
          Text(
            displayedUSDBalance,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          FTooltip(
            tipBuilder: (context, controller) {
              return Text(loc.percentage_change_24h);
            },
            child: Row(
              children: [
                Icon(
                  isPositiveChange ? FIcons.chevronUp : FIcons.chevronDown,
                  color: isPositiveChange
                      ? context.theme.colors.upColor
                      : context.theme.colors.downColor,
                  size: 16,
                ),
                Text(
                  displayedPercentChange24h,
                  style: context.theme.typography.sm.copyWith(
                    color: isPositiveChange
                        ? context.theme.colors.upColor
                        : context.theme.colors.downColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (priceHistory24h.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Spaces.extraSmall),
              child: XelisPriceSparkline(
                pricePoints: response.pricePoints,
                sparklineColor: sparklineColor,
              ),
            ),
        ],
      );
    } else {
      return CustomSkeletonizer(
        child: Row(
          children: [
            Text('Dummy USDT Balance'),
            SizedBox(width: Spaces.medium),
            Text('Dummy Change'),
            SizedBox(width: 100, height: 24),
          ],
        ),
      );
    }
  }
}
