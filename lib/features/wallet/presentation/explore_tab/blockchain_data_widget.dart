import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/daemon_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class BlockchainData extends StatelessWidget {
  const BlockchainData({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Blockchain',
                style: context.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Topoheight',
                            style: context.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Consumer(
                            builder: (
                              BuildContext context,
                              WidgetRef ref,
                              Widget? child,
                            ) {
                              final topoHeight = ref.watch(
                                networkTopoHeightProvider,
                              );
                              return topoHeight.when(
                                skipLoadingOnReload: true,
                                data: (data) {
                                  return Text(
                                    data.toString(),
                                    style: context.bodyLarge,
                                  );
                                  // return AnimatedSwitcher(
                                  //   duration: const Duration(milliseconds: 200),
                                  //   child: Text(
                                  //     data.toString(),
                                  //     key: ValueKey<String>(
                                  //       data.toString(),
                                  //     ),
                                  //     style: context.bodyLarge,
                                  //   ),
                                  // );
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
                            'Last Block',
                            style: context.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Consumer(
                            builder: (
                              BuildContext context,
                              WidgetRef ref,
                              Widget? child,
                            ) {
                              final timer = ref.watch(lastBlockTimerProvider);
                              return Text(
                                '$timer s',
                                style: context.bodyLarge,
                              );
                              // return AnimatedSwitcher(
                              //   duration: const Duration(milliseconds: 400),
                              //   child: Text(
                              //     '$timer s',
                              //     key: ValueKey<String>(
                              //       '$timer s',
                              //     ),
                              //     style: context.bodyLarge,
                              //   ),
                              // );
                            },
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Hashrate',
                            style: context.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Consumer(
                            builder: (
                              BuildContext context,
                              WidgetRef ref,
                              Widget? child,
                            ) {
                              final syncedHeight =
                                  ref.watch(networkHashrateProvider);
                              return syncedHeight.when(
                                skipLoadingOnReload: true,
                                data: (data) {
                                  return Text(
                                    '${NumberFormat.compact().format(data / 15)}H/s',
                                    style: context.bodyLarge,
                                  );
                                  // return AnimatedSwitcher(
                                  //   duration: const Duration(milliseconds: 200),
                                  //   child: Text(
                                  //     '${NumberFormat.compact().format(data / 15)}H/s',
                                  //     key: ValueKey<String>(
                                  //       '${NumberFormat.compact().format(data / 15)}H/s',
                                  //     ),
                                  //     style: context.bodyLarge,
                                  //   ),
                                  // );
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
                            'Total Supply',
                            style: context.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Consumer(
                            builder: (
                              BuildContext context,
                              WidgetRef ref,
                              Widget? child,
                            ) {
                              final syncedHeight = ref.watch(
                                networkNativeSupplyProvider,
                              );
                              return syncedHeight.when(
                                skipLoadingOnReload: true,
                                data: (data) {
                                  return Text(
                                    // data.toStringAsPrecision(5),
                                    (data / pow(10, 5)).toStringAsFixed(2),
                                    key: ValueKey<String>(
                                      (data / pow(10, 5)).toStringAsFixed(2),
                                    ),
                                    style: context.bodyLarge,
                                  );
                                  // return AnimatedSwitcher(
                                  //   duration: const Duration(milliseconds: 200),
                                  //   child: Text(
                                  //     // data.toStringAsPrecision(5),
                                  //     (data / pow(10, 5)).toStringAsFixed(2),
                                  //     key: ValueKey<String>(
                                  //       (data / pow(10, 5)).toStringAsFixed(2),
                                  //     ),
                                  //     style: context.bodyLarge,
                                  //   ),
                                  // );
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
                      'Mempool',
                      style: context.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Consumer(
                      builder: (
                        BuildContext context,
                        WidgetRef ref,
                        Widget? child,
                      ) {
                        final mempool = ref.watch(networkMempoolProvider);
                        return mempool.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            return Text(
                              data.toString(),
                              style: context.bodyLarge,
                            );
                            // return AnimatedSwitcher(
                            //   duration: const Duration(milliseconds: 200),
                            //   child: Text(
                            //     data.toString(),
                            //     key: ValueKey<String>(
                            //       data.toString(),
                            //     ),
                            //     style: context.bodyLarge,
                            //   ),
                            // );
                          },
                          error: (err, stack) => Text(
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
          ],
        ),
      ),
    );
  }
}
