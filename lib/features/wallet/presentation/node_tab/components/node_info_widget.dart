import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/node_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NodeInfoWidget extends ConsumerWidget {
  const NodeInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final info = ref.watch(getInfoProvider);

    return switch (info) {
      AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.network,
              style:
                  context.bodyMedium?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              switch (value?.network) {
                Network.mainnet => 'Mainnet',
                Network.testnet => 'Testnet',
                null => '...',
              },
              style: context.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              loc.node_type,
              style:
                  context.bodyMedium?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              switch (value?.pruned) {
                null => '...',
                true => loc.pruned_node,
                false => loc.full_node,
              },
              style: context.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              loc.circulating_supply,
              style:
                  context.bodyMedium?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${value?.circulatingSupply ?? '...'} XEL',
              style: context.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              loc.average_block_time,
              style:
                  context.bodyMedium?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${value?.averageBlockTime.inSeconds.toString() ?? '...'} ${loc.seconds}',
              style: context.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              loc.version,
              style:
                  context.bodyMedium?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              value?.version ?? '...',
              style: context.titleMedium,
            ),
            const SizedBox(height: 24),
          ],
        ),
      AsyncError() => Center(
          child: Text(
            loc.oups,
            style: context.bodyLarge,
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
