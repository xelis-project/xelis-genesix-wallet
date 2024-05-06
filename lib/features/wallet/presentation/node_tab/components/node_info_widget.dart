import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/node_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';

class NodeInfoWidget extends ConsumerWidget {
  const NodeInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final info = ref.watch(getInfoProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.network,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          switch (info?.network) {
            Network.mainnet => 'Mainnet',
            Network.testnet => 'Testnet',
            Network.dev => 'Dev',
            null => '...',
          },
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.topoheight,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          switch (info?.topoHeight) {
            null => '...',
            int() => info!.topoHeight.toString(),
          },
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.node_type,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          switch (info?.pruned) {
            null => '...',
            true => loc.pruned_node,
            false => loc.full_node,
          },
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.circulating_supply,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          switch (info?.circulatingSupply) {
            null => '...',
            String() => '${info?.circulatingSupply} XEL',
          },
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.block_reward,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          info?.blockReward.toString() != null
              ? '${formatXelis(info!.blockReward)} XEL'
              : '...',
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          'Mempool',
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          info?.mempoolSize.toString() ?? '...',
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.average_block_time,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          switch (info?.averageBlockTime) {
            null => '...',
            Duration() =>
              '${info?.averageBlockTime.inSeconds.toString()} ${loc.seconds}'
          },
          style: context.titleLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.version,
          style: context.labelLarge?.copyWith(color: context.colors.primary),
        ),
        SelectableText(
          info?.version ?? '...',
          style: context.titleLarge,
        ),
      ],
    );
  }
}
