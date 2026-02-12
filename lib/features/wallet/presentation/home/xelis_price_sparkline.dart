import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coingecko/xelis_price_point.dart';
import 'package:genesix/shared/utils/utils.dart';

class XelisPriceSparkline extends StatelessWidget {
  const XelisPriceSparkline({
    super.key,
    required this.pricePoints,
    required this.sparklineColor,
    required this.currencySymbol,
  });

  final List<XelisPricePoint> pricePoints;
  final Color sparklineColor;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final history = pricePoints.map((e) => e.price).toList();
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 100,
      height: 24,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, indicators) {
              return indicators.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, idx) =>
                        FlDotCirclePainter(
                          radius: 3, // Adjust radius as needed
                          color: sparklineColor,
                          strokeWidth: 0,
                        ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              fitInsideVertically: true,
              getTooltipColor: (LineBarSpot touchedSpot) => Colors.transparent,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    formatCurrency(spot.y, currencySymbol),
                    TextStyle(
                      color: context.theme.colors.foreground,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < history.length; i++)
                  FlSpot(i.toDouble(), history[i]),
              ],
              isCurved: true,
              color: sparklineColor.withValues(alpha: 0.8),
              dotData: FlDotData(show: false),
              barWidth: 2,
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minY: history.reduce((a, b) => a < b ? a : b),
          maxY: history.reduce((a, b) => a > b ? a : b),
        ),
      ),
    );
  }
}
