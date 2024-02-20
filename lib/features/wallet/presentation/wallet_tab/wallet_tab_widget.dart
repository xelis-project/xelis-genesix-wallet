import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/balance_mode_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/balance_mode_state.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/qr_dialog.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/seed_dialog.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/transfer_to_dialog.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletSnapshot = ref.watch(walletStateProvider);
    final balanceModeState = ref.watch(balanceModeProvider);

    Widget svgAvatar = walletSnapshot.address.isNotEmpty
        ? RandomAvatar(walletSnapshot.address, height: 50, width: 50)
        : const SizedBox.shrink();

    ValueNotifier<bool> isRescanningNotifier = ValueNotifier(false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 32.0),
      child: ListView(
        children: [
          Card(
            elevation: 4,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                          const SizedBox(width: 16),
                          Text(
                            walletSnapshot.name,
                            style: context.displaySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            walletSnapshot.address.isNotEmpty
                                ? '.' * 3 +
                                    walletSnapshot.address.substring(
                                        walletSnapshot.address.length - 8)
                                : '...',
                            maxLines: 1,
                            style: context.bodyMedium,
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                      text: walletSnapshot.address))
                                  .then((_) {
                                ref
                                    .read(snackbarContentProvider.notifier)
                                    .setContent(SnackbarEvent.info(
                                        message: loc.copied));
                              });
                            },
                            icon: const Icon(
                              Icons.copy,
                              size: 18,
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
                        icon: const Icon(Icons.pattern),
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'Seed',
                          maxLines: 1,
                          style: context.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              )),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridTile(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.topoheight,
                        style: context.bodyMedium
                            ?.copyWith(color: context.colors.primary),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          key: ValueKey<int>(walletSnapshot.topoheight),
                          walletSnapshot.topoheight.toString(),
                          style: context.displaySmall,
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
                            icon: const Icon(Icons.sync),
                            color: context.colors.primary,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'Rescan',
                          maxLines: 1,
                          style: context.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              )),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridTile(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.balance,
                    style: context.bodyMedium
                        ?.copyWith(color: context.colors.primary),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ImageFiltered(
                                enabled: balanceModeState.hide,
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    key: ValueKey<String>(
                                        walletSnapshot.xelisBalance),
                                    walletSnapshot.xelisBalance,
                                    maxLines: 1,
                                    // overflow: TextOverflow.fade,
                                    // softWrap: true,
                                    style: context.displaySmall,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'XEL',
                                maxLines: 1,
                                style: context.displaySmall,
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton.outlined(
                            icon: balanceModeState.hide
                                ? Icon(
                                    Icons.visibility_outlined,
                                    color: context.colors.primary,
                                  )
                                : Icon(
                                    Icons.visibility_off_outlined,
                                    color: context.colors.primary,
                                  ),
                            onPressed: () {
                              ref
                                  .read(balanceModeProvider.notifier)
                                  .setBalanceMode(BalanceModeState(
                                      hide: !balanceModeState.hide));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '.... USD',
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                            color: context.colors.primary,
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              loc.send,
                              maxLines: 1,
                              style: context.bodyMedium,
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
                                  .setContent(const SnackbarEvent.info(
                                      message: 'Burn!'));
                            },
                            icon: const Icon(
                                Icons.local_fire_department_outlined),
                            color: context.colors.primary,
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'Burn',
                              maxLines: 1,
                              style: context.bodyMedium,
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
                            color: context.colors.primary,
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              loc.receive,
                              maxLines: 1,
                              style: context.bodyMedium,
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
