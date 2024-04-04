import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/balance_widget.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/wallet_address_widget.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';

class WalletTab extends ConsumerStatefulWidget {
  const WalletTab({super.key});

  @override
  ConsumerState<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends ConsumerState<WalletTab> {
  void _copy(String content, String message) {
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      ref
          .read(snackbarContentProvider.notifier)
          .setContent(SnackbarEvent.info(message: message));
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletSnapshot = ref.watch(walletStateProvider);

    ValueNotifier<bool> isRescanningNotifier = ValueNotifier(false);

    var displayTopo = NumberFormat().format(walletSnapshot.topoheight);

    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: [
        const WalletAddressWidget(),
        const SizedBox(height: Spaces.large),
        const BalanceWidget(),
        const SizedBox(height: Spaces.large),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(Spaces.medium),
            child: GridTile(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.topoheight,
                      style: context.titleMedium!
                          .copyWith(color: context.moreColors.mutedColor),
                    ),
                    AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: AppDurations.animFast),
                      child: SelectableText(
                        key: ValueKey<String>(displayTopo),
                        displayTopo,
                        style: context.headlineLarge,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: isRescanningNotifier,
                      builder:
                          (BuildContext context, bool isRescanning, Widget? _) {
                        return IconButton.outlined(
                          onPressed: isRescanning
                              ? null
                              : () async {
                                  isRescanningNotifier.value = true;
                                  await ref
                                      .read(walletStateProvider.notifier)
                                      .rescan();
                                  isRescanningNotifier.value = false;
                                },
                          icon: const Icon(Icons.sync_rounded),
                        );
                      },
                    ),
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        'Rescan',
                        maxLines: 1,
                        style: context.labelMedium,
                      ),
                    ),
                  ],
                ),
              ],
            )),
          ),
        ),
      ],
    );
  }
}
