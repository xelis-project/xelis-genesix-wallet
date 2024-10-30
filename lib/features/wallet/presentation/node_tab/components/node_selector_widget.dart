import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_mismatch_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/presentation/node_tab/components/add_node_dialog.dart';
import 'package:genesix/features/wallet/presentation/node_tab/components/modify_node_dialog.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';

class NodeSelectorWidget extends ConsumerStatefulWidget {
  const NodeSelectorWidget({
    super.key,
  });

  @override
  ConsumerState createState() => NodeSelectorWidgetState();
}

class NodeSelectorWidgetState extends ConsumerState<NodeSelectorWidget> {
  void _onDismissed(NodeAddress node) {
    final settings = ref.read(settingsProvider);
    ref.read(networkNodesProvider.notifier).removeNode(settings.network, node);
  }

  void _onNodeAddressSelected(NodeAddress? value) {
    if (value != null) {
      ref.read(walletStateProvider.notifier).reconnect(value);
    }
  }

  void _showNewAddressDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => const AddNodeDialog(),
    );
  }

  void _showUpdateAddressDialog(BuildContext context, NodeAddress nodeAddress) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModifyNodeDialog(nodeAddress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final networkNodes = ref.watch(networkNodesProvider);
    final network =
        ref.watch(settingsProvider.select((state) => state.network));
    final isOnline =
        ref.watch(walletStateProvider.select((value) => value.isOnline));
    bool mismatch = ref.watch(networkMismatchProvider);

    var nodeAddress = networkNodes.getNodeAddress(network);
    var nodes = networkNodes.getNodes(network);
    return Card(
      child: Theme(
        data: context.theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Tooltip(
            message: isOnline
                ? loc.connected
                : mismatch
                    ? loc.network_mismatch
                    : loc.disconnected,
            child: Icon(
              isOnline
                  ? Icons.sensors
                  : mismatch
                      ? Icons.warning_amber
                      : Icons.sensors_off,
              color: isOnline ? context.colors.primary : context.colors.error,
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          tilePadding: const EdgeInsets.fromLTRB(
              Spaces.medium, Spaces.small, Spaces.medium, Spaces.small),
          title: Text(
            nodeAddress.name,
            style: context.titleLarge,
          ),
          subtitle: Text(
            nodeAddress.url,
            style: context.titleMedium!
                .copyWith(color: context.moreColors.mutedColor),
          ),
          children: [
            ...List<Dismissible>.generate(
              nodes.length,
              (index) => Dismissible(
                key: ValueKey<NodeAddress>(nodes[index]),
                onDismissed: (direction) {
                  _onDismissed(nodes[index]);
                },
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: Spaces.medium),
                  title: Text(
                    nodes[index].name,
                    style: context.bodyLarge,
                  ),
                  subtitle: Text(
                    nodes[index].url,
                    style: context.bodyMedium,
                  ),
                  leading: Radio<NodeAddress>(
                    value: nodes[index],
                    groupValue: nodeAddress,
                    onChanged: _onNodeAddressSelected,
                  ),
                  trailing: MenuAnchor(
                    builder: (BuildContext context, MenuController controller,
                        Widget? child) {
                      return IconButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        icon: const Icon(Icons.more_vert),
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        child: Text(
                          loc.modify,
                          style: context.bodyMedium,
                        ),
                        onPressed: () {
                          _showUpdateAddressDialog(context, nodes[index]);
                        },
                      ),
                      if (nodeAddress == nodes[index])
                        MenuItemButton(
                          child: Text(
                            loc.reconnect,
                            style: context.bodyMedium,
                          ),
                          onPressed: () {
                            _onNodeAddressSelected(nodes[index]);
                          },
                        ),
                      MenuItemButton(
                        child: Text(
                          loc.remove,
                          style: context.bodyMedium,
                        ),
                        onPressed: () {
                          _onDismissed(nodes[index]);
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: FilledButton(
                onPressed: () => _showNewAddressDialog(context),
                child: Text(
                  loc.add_node_button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
