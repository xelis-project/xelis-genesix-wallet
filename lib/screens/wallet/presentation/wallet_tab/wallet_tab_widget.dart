import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/qr_dialog.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/seed_dialog.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/transfer_to_dialog.dart';
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

  void _showSeedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const MySeedDialog(),
    );
  }

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
    final settings = ref.watch(settingsProvider);

    Widget svgAvatar = walletSnapshot.address.isNotEmpty
        ? RandomAvatar(walletSnapshot.address, height: 50, width: 50)
        : const SizedBox.shrink();

    ValueNotifier<bool> isRescanningNotifier = ValueNotifier(false);

    final truncatedWalletAddress = walletSnapshot.address.isNotEmpty
        ? '.' * 3 +
            walletSnapshot.address.substring(walletSnapshot.address.length - 8)
        : '...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spaces.medium, Spaces.extraLarge, Spaces.medium, Spaces.extraLarge),
      child: ListView(
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: GridTile(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          svgAvatar,
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.wallet_name_capitalize,
                                style: context.labelLarge
                                    ?.copyWith(color: context.colors.primary),
                              ),
                              Text(
                                walletSnapshot.name,
                                style: context.headlineMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: Spaces.large),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.wallet_address_capitalize,
                            style: context.labelLarge
                                ?.copyWith(color: context.colors.primary),
                          ),
                          Tooltip(
                            message: walletSnapshot.address,
                            child: InkWell(
                              onTap: () =>
                                  _copy(walletSnapshot.address, loc.copied),
                              borderRadius: BorderRadius.circular(4),
                              child: Text(
                                truncatedWalletAddress,
                                style: context.headlineSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton.outlined(
                        onPressed: () {
                          _showSeedDialog(context);
                        },
                        icon: const Icon(Icons.pattern_rounded),
                      ),
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'Seed',
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
          const SizedBox(height: Spaces.medium),
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
                        style: context.labelLarge
                            ?.copyWith(color: context.colors.primary),
                      ),
                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: AppDurations.animFast),
                        child: Text(
                          key: ValueKey<int>(walletSnapshot.topoheight),
                          walletSnapshot.topoheight.toString(),
                          style: context.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: isRescanningNotifier,
                        builder: (BuildContext context, bool isRescanning,
                            Widget? _) {
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
          const SizedBox(height: Spaces.medium),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: GridTile(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.balance,
                    style: context.labelLarge
                        ?.copyWith(color: context.colors.primary),
                  ),
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
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(
                                      milliseconds: AppDurations.animFast),
                                  child: Text(
                                    key: ValueKey<String>(
                                        walletSnapshot.xelisBalance),
                                    walletSnapshot.xelisBalance,
                                    maxLines: 1,
                                    style: context.headlineMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Spaces.small),
                              Text(
                                'XEL',
                                maxLines: 1,
                                style: context.headlineLarge,
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton.outlined(
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
                      const SizedBox(height: Spaces.medium),
                      Text(
                        '.... USD',
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spaces.small),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton.outlined(
                            onPressed: () {
                              _showTransferToDialog(context);
                            },
                            icon: const Icon(Icons.call_made_rounded),
                          ),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              loc.send,
                              maxLines: 1,
                              style: context.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton.outlined(
                            onPressed: () {
                              // TODO
                              ref
                                  .read(snackbarContentProvider.notifier)
                                  .setContent(SnackbarEvent.info(
                                      message: loc.coming_soon));
                            },
                            icon:
                                const Icon(Icons.local_fire_department_rounded),
                          ),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'Burn',
                              maxLines: 1,
                              style: context.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton.outlined(
                            onPressed: () {
                              _showQrDialog(context);
                            },
                            icon: const Icon(Icons.call_received_rounded),
                          ),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              loc.receive,
                              maxLines: 1,
                              style: context.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}
