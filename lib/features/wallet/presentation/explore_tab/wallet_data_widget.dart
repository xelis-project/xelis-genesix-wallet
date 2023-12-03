import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class WalletData extends StatelessWidget {
  const WalletData({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Wallet',
                      style: context.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Name',
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Consumer(
                      builder:
                          (BuildContext context, WidgetRef ref, Widget? child) {
                        final walletName = ref.watch(walletNameProvider);
                        return walletName.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            return Text(
                              data,
                              style: context.bodyLarge,
                            );
                          },
                          error: (err, stack) => Text(
                            // 'Error: $err',
                            '/',
                            style: context.bodyLarge,
                          ),
                          loading: () => LoadingAnimationWidget.waveDots(
                            color: context.colors.primary,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Topoheight',
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Consumer(
                      builder:
                          (BuildContext context, WidgetRef ref, Widget? child) {
                        final topoHeight =
                            ref.watch(walletCurrentTopoHeightProvider);
                        return topoHeight.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            return Text(
                              data.toString(),
                              style: context.bodyLarge,
                            );
                          },
                          error: (err, stack) => Text(
                            // 'Error: $err',
                            '/',
                            style: context.bodyLarge,
                          ),
                          loading: () => LoadingAnimationWidget.waveDots(
                            color: context.colors.primary,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Address',
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Consumer(
                      builder:
                          (BuildContext context, WidgetRef ref, Widget? child) {
                        final walletAddress = ref.watch(walletAddressProvider);
                        return walletAddress.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            return Text(
                              data,
                              style: context.bodyLarge,
                            );
                          },
                          error: (err, stack) => Text(
                            // 'Error: $err',
                            '/',
                            style: context.bodyMedium,
                          ),
                          loading: () => LoadingAnimationWidget.waveDots(
                            color: context.colors.primary,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Balance',
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Consumer(
                      builder:
                          (BuildContext context, WidgetRef ref, Widget? child) {
                        final xelisBalance =
                            ref.watch(walletXelisBalanceProvider);
                        logger.info('xelisBalance: $xelisBalance');
                        return xelisBalance.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            final balance = data.balance != null
                                ? '${(data.balance!) / pow(10, 5)} XEL'
                                : '0 XEL';
                            return Text(
                              balance,
                              style: context.bodyLarge,
                            );
                          },
                          error: (err, stack) => Text(
                            // 'Error: $err',
                            '/',
                            style: context.bodyLarge,
                          ),
                          loading: () => LoadingAnimationWidget.waveDots(
                            color: context.colors.primary,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          // TODO change this behavior
                          // ref.read(walletServicePodProvider.future).then(
                          //       (wallet) => wallet.syncFromTopoHeight(1),
                          //     );
                        },
                        child: const Text('Rescan'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          logger.info('Address Book');
                        },
                        child: const Text('Address Book'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(walletSeedProvider.future).then((seed) {
                            _showSeed(context, seed);
                          });
                        },
                        child: const Text('Seed'),
                      ),
                      // const Spacer(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeed(BuildContext context, String seed) {
    showDialog<dynamic>(
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Seed',
            style: context.displaySmall,
            textAlign: TextAlign.center,
          ),
          content: SelectionArea(
            child: Text(
              seed,
              style: context.bodyLarge,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
      context: context,
    );
  }
}
