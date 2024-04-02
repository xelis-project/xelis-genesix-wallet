import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/qr_dialog.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/transfer_to_dialog.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class BalanceWidget extends ConsumerWidget {
  const BalanceWidget({super.key});

  void _showTransferToDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const TransferToDialog(),
    );
  }

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
    final walletSnapshot = ref.watch(walletStateProvider);

    return GridTile(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.balance,
            style: context.headlineSmall,
          ),
          const SizedBox(height: Spaces.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ImageFiltered(
                        enabled: settings.hideBalance,
                        imageFilter: ImageFilter.blur(
                          sigmaX: 15,
                          sigmaY: 15,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(
                              milliseconds: AppDurations.animFast),
                          child: Text(
                            key: ValueKey<String>(walletSnapshot.xelisBalance),
                            '${walletSnapshot.xelisBalance} XEL',
                            maxLines: 1,
                            style: context.headlineLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filled(
                    icon: settings.hideBalance
                        ? const Icon(
                            Icons.visibility_rounded,
                          )
                        : const Icon(
                            Icons.visibility_off_rounded,
                          ),
                    onPressed: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setHideBalance(!settings.hideBalance);
                    },
                  ),
                ],
              ),
              Text(
                '1000.00 usdt',
                style: context.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: Spaces.large),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: Spaces.medium,
            children: [
              Column(
                children: [
                  IconButton.filled(
                    onPressed: () {
                      _showTransferToDialog(context);
                    },
                    icon: const Icon(Icons.call_made_rounded),
                  ),
                  const SizedBox(height: Spaces.small),
                  Text(loc.send),
                ],
              ),
              Column(
                children: [
                  IconButton.filled(
                    onPressed: () {
                      // TODO
                      ref.read(snackbarContentProvider.notifier).setContent(
                          SnackbarEvent.info(message: loc.coming_soon));
                    },
                    icon: const Icon(Icons.local_fire_department_rounded),
                  ),
                  const SizedBox(height: Spaces.small),
                  Text('Burn'),
                ],
              ),
              Column(
                children: [
                  IconButton.filled(
                    onPressed: () {
                      _showQrDialog(context);
                    },
                    icon: const Icon(Icons.call_received_rounded),
                  ),
                  const SizedBox(height: Spaces.small),
                  Text(loc.receive),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
