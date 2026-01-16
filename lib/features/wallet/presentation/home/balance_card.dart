import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/home/receive_address_dialog.dart';
import 'package:genesix/features/wallet/presentation/home/usd_balance_widget.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:go_router/go_router.dart';

class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({super.key});

  @override
  ConsumerState createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  final String hidden = '********';

  void _showReceiveDialog() {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return ReceiveAddressDialog(style, animation);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final settings = ref.watch(settingsProvider);
    final walletState = ref.watch(walletStateProvider);

    var displayedBalance =
        '${walletState.xelisBalance.isNotEmpty ? walletState.xelisBalance : AppResources.zeroBalance} ${getXelisTicker(settings.network)}';

    if (settings.hideBalance) {
      displayedBalance = hidden;
    }

    final isMainnet = settings.network == Network.mainnet;

    return FCard.raw(
      child: Padding(
        padding: EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.balance,
                  style: context.theme.typography.xl.copyWith(
                    color: context.theme.colors.primary,
                  ),
                ),
                FButton.icon(
                  onPress: () => ref
                      .read(settingsProvider.notifier)
                      .setHideBalance(!settings.hideBalance),
                  child: settings.hideBalance
                      ? const Icon(FIcons.eye)
                      : const Icon(FIcons.eyeOff),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  key: ValueKey(settings.hideBalance),
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spaces.extraSmall,
                  children: [
                    Text(
                      displayedBalance,
                      style: context.theme.typography.xl2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.colors.foreground,
                      ),
                    ),
                    if ((settings.showBalanceUSDT && isMainnet) ||
                        (settings.showBalanceUSDT && kDebugMode))
                      // Show USD balance only on mainnet
                      UsdBalanceWidget(
                        double.tryParse(walletState.xelisBalance) ?? 0.0,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Spaces.large),
            Row(
              children: [
                FButton(
                  style: FButtonStyle.outline(),
                  prefix: Icon(FIcons.arrowUpRight),
                  onPress: () => context.push(AuthAppScreen.transfer.toPath),
                  child: Text(loc.send),
                ),
                const SizedBox(width: Spaces.small),
                FButton(
                  style: FButtonStyle.outline(),
                  prefix: Icon(FIcons.arrowDownLeft),
                  onPress: _showReceiveDialog,
                  child: Text(loc.receive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
