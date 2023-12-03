import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/application/node_addresses_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/daemon_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NodeData extends StatelessWidget {
  const NodeData({super.key});

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
                'Node',
                style: context.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
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
                        final connectionState = ref.watch(daemonStateProvider);
                        return connectionState.when(
                          skipLoadingOnReload: true,
                          data: (socketState) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                socketState,
                                key: ValueKey<String>(
                                  socketState,
                                ),
                                style: context.bodyLarge,
                              ),
                            );
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
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Endpoint',
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
                        final currentEndpoint = ref.watch(
                          nodeAddressesProvider.select(
                            (state) => state.favorite,
                          ),
                        );
                        return Text(
                          currentEndpoint,
                          style: context.bodyLarge,
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
                      'Version',
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
                        final currentEndpoint =
                            ref.watch(daemonVersionProvider);
                        return currentEndpoint.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                data,
                                key: ValueKey<String>(
                                  data,
                                ),
                                style: context.bodyLarge,
                              ),
                            );
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
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Network',
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
                        final networkType = ref.watch(daemonNetworkProvider);
                        return networkType.when(
                          skipLoadingOnReload: true,
                          data: (data) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                data,
                                key: ValueKey<String>(
                                  data,
                                ),
                                style: context.bodyLarge,
                              ),
                            );
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
