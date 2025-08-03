import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
    final xelisCoingeckoResponse = ref.watch(xelisPriceProvider.future);

    return FutureBuilder(
      future: xelisCoingeckoResponse,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.hasData) {
          final xelisPrice = asyncSnapshot.data?.price.usd ?? 0.0;
          final usdtBalance = xelisPrice * widget.xelisBalance;
          var displayedUSDBalance = formatUsd(usdtBalance);

          final percentChange24h =
              asyncSnapshot.data?.price.usd24hChange ?? 0.0;
          final isPositiveChange = percentChange24h >= 0;
          var displayedPercentChange24h =
              '${percentChange24h.abs().toStringAsFixed(2)}%';

          if (hideBalance) {
            displayedUSDBalance = hidden;
            displayedPercentChange24h = hidden;
          }

          final priceHistory24h =
              asyncSnapshot.data?.pricePoints.map((e) => e.price).toList() ??
              [];
          final sparklineColor = isPositiveChange
              ? context.theme.colors.upColor
              : context.theme.colors.downColor;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayedUSDBalance,
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(width: Spaces.medium),
              FTooltip(
                tipBuilder: (context, controller) {
                  return Text('Percentage change in 24 hours');
                },
                child: Row(
                  children: [
                    if (!hideBalance) ...[
                      Icon(
                        isPositiveChange
                            ? FIcons.chevronUp
                            : FIcons.chevronDown,
                        color: isPositiveChange
                            ? context.theme.colors.upColor
                            : context.theme.colors.downColor,
                        size: 16,
                      ),
                    ],
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
              const SizedBox(width: Spaces.medium),
              if (priceHistory24h.isNotEmpty && !hideBalance)
                Padding(
                  padding: const EdgeInsets.only(top: Spaces.extraSmall),
                  child: XelisPriceSparkline(
                    pricePoints: asyncSnapshot.data?.pricePoints ?? [],
                    sparklineColor: sparklineColor,
                  ),
                ),
            ],
          );
        }
        return CustomSkeletonizer(
          child: Row(
            children: [
              Text('Dummy USDT Balance'),
              const SizedBox(width: Spaces.medium),
              Text('Dummy Change'),
              const SizedBox(width: Spaces.medium),
              SizedBox(width: 100, height: 24),
            ],
          ),
        );
      },
    );
  }
}
