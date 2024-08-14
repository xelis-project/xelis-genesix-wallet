import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/xelis_price_provider.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coinpaprika/xelis_ticker.dart';
import 'package:genesix/rust_bridge/api/network.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/qr_dialog.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:intl/intl.dart';

class BalanceWidget extends ConsumerWidget {
  const BalanceWidget({super.key});

  void _showQrDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const QrDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final settings = ref.watch(settingsProvider);
    final xelisBalance =
        ref.watch(walletStateProvider.select((state) => state.xelisBalance));

    XelisTicker? xelisTicker;
    if (settings.showBalanceUSDT && settings.network == Network.mainnet) {
      xelisTicker = ref.watch(xelisPriceProvider).valueOrNull;
    }
    var xelisPrice =
        (xelisTicker?.price ?? 0.0) * (double.tryParse(xelisBalance) ?? 0.0);

    var displayBalance = xelisBalance;
    if (settings.hideBalance) {
      displayBalance = loc.hidden;
      xelisPrice = 0.0;
    }

    return GridTile(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.balance,
            style: context.headlineSmall!
                .copyWith(color: context.moreColors.mutedColor),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Row(
              key: UniqueKey(),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectionArea(
                        child: AutoSizeText(
                          displayBalance,
                          maxLines: 1,
                          style: context.displayMedium,
                          minFontSize: 20,
                        ),
                      ),
                      if (settings.showBalanceUSDT &&
                          settings.network == Network.mainnet) ...[
                        const SizedBox(height: 3),
                        SelectableText('${xelisPrice.toStringAsFixed(2)} USDT',
                            style: context.bodyLarge)
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Spaces.medium),
                IconButton.filled(
                  icon: settings.hideBalance
                      ? const Icon(
                          Icons.visibility_rounded,
                        )
                      : const Icon(
                          Icons.visibility_off_rounded,
                        ),
                  tooltip: settings.hideBalance
                      ? loc.show_balance
                      : loc.hide_balance,
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setHideBalance(!settings.hideBalance),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spaces.large),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: Spaces.medium,
            children: [
              Column(
                children: [
                  IconButton.filled(
                    onPressed: () => context.push(AppScreen.transfer.toPath),
                    icon: const Icon(Icons.call_made_rounded),
                  ),
                  const SizedBox(height: Spaces.extraSmall),
                  Text(loc.send, style: context.labelLarge),
                ],
              ),
              Column(
                children: [
                  IconButton.filled(
                    onPressed: settings.unlockBurn
                        ? () => context.push(AppScreen.burn.toPath)
                        : null,
                    icon: const Icon(Icons.local_fire_department_rounded),
                    tooltip: settings.unlockBurn
                        ? null
                        : toBeginningOfSentenceCase(loc.unlock_in_settings),
                  ),
                  const SizedBox(height: Spaces.extraSmall),
                  Text(
                    loc.burn,
                    style: context.labelLarge?.copyWith(
                        color: settings.unlockBurn
                            ? context.colors.onSurface
                            : context.moreColors.mutedColor),
                  ),
                ],
              ),
              Column(
                children: [
                  IconButton.filled(
                    onPressed: () => _showQrDialog(context),
                    icon: const Icon(Icons.call_received_rounded),
                  ),
                  const SizedBox(height: Spaces.extraSmall),
                  Text(loc.receive, style: context.labelLarge),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
