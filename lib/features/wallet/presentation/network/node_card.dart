import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/presentation/network/add_node_sheet.dart';
import 'package:genesix/features/wallet/presentation/network/edit_node_sheet.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/connection_indicator.dart';

class NodeCard extends ConsumerStatefulWidget {
  const NodeCard(this.info, {super.key});

  final DaemonInfoSnapshot? info;

  @override
  ConsumerState<NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends ConsumerState<NodeCard> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final isOnline = ref.watch(
      walletStateProvider.select((value) => value.isOnline),
    );
    final networkNodes = ref.watch(networkNodesProvider);
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );

    List<NodeAddress> nodes = networkNodes.nodesFor(network);
    NodeAddress nodeAddress = networkNodes.addressFor(network);

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          spacing: Spaces.medium,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  loc.version.toLowerCase(),
                  style: context.theme.typography.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: Spaces.extraSmall),
                Text(
                  widget.info?.version ?? '...',
                  style: context.theme.typography.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            FSelectMenuTile.builder(
              key: ValueKey(nodeAddress),
              title: Text(loc.node),
              subtitle: Text(widget.info?.network?.name ?? loc.unknown_network),
              count: nodes.length,
              initialValue: nodeAddress,
              detailsBuilder: (_, values, _) => Text(values.first.name),
              menuBuilder: (context, index) => FSelectTile(
                title: Text(nodes[index].name),
                subtitle: Text(nodes[index].url),
                value: nodes[index],
              ),
              onSelect: (selection) {
                ref
                    .read(networkNodesProvider.notifier)
                    .setNodeAddress(network, selection.$1);
                ref.read(walletStateProvider.notifier).reconnect(selection.$1);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ConnectionIndicator(),
                Row(
                  spacing: Spaces.small,
                  children: [
                    FTooltip(
                      tipBuilder: (context, controller) => Text(loc.add_node),
                      child: FButton.icon(
                        onPress: () => showAddNodeSheet(context),
                        child: Icon(FIcons.plus),
                      ),
                    ),
                    FTooltip(
                      tipBuilder: (context, controller) => Text(loc.edit_node),
                      child: FButton.icon(
                        onPress: () => showEditNodeSheet(context, nodeAddress),
                        child: Icon(FIcons.pencil),
                      ),
                    ),
                    FTooltip(
                      tipBuilder: (context, controller) =>
                          Text(loc.connect_node),
                      child: FButton.icon(
                        onPress: !isOnline
                            ? () => ref
                                  .read(walletStateProvider.notifier)
                                  .reconnect(nodeAddress)
                            : null,
                        child: Icon(FIcons.play),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showAddNodeSheet(BuildContext context) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => AddNodeSheet(),
    );
  }

  void showEditNodeSheet(BuildContext context, NodeAddress nodeAddress) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => EditNodeSheet(nodeAddress),
    );
  }
}
