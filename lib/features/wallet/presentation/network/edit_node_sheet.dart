import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';
import 'package:go_router/go_router.dart';

class EditNodeSheet extends ConsumerStatefulWidget {
  const EditNodeSheet(this.nodeAddress, {super.key});

  final NodeAddress nodeAddress;

  @override
  ConsumerState<EditNodeSheet> createState() => _EditNodeSheetState();
}

class _EditNodeSheetState extends ConsumerState<EditNodeSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.nodeAddress.name;
    _urlController.text = widget.nodeAddress.url;
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return SheetContent(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FTextFormField(
              controller: _nameController,
              label: Text(loc.node_name),
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              controller: _urlController,
              label: Text(loc.node_url),
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                if (!Uri.tryParse(value)!.hasScheme) {
                  return loc.node_url_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.large),
            FButton(
              child: Text(loc.save_node),
              onPress: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _edit(
                    NodeAddress(
                      name: _nameController.text,
                      url: _urlController.text,
                    ),
                  );
                  context.pop();
                }
              },
            ),
            const SizedBox(height: Spaces.medium),
            FButton(
              style: FButtonStyle.destructive(),
              child: Text(loc.delete_node),
              onPress: () {
                _delete(
                  NodeAddress(
                    name: _nameController.text,
                    url: _urlController.text,
                  ),
                );
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _edit(NodeAddress? newValue) {
    if (newValue != null) {
      final network = ref.read(settingsProvider).network;
      ref
          .read(networkNodesProvider.notifier)
          .updateNode(network, widget.nodeAddress, newValue);
      // Update the node address in the provider
      ref.read(networkNodesProvider.notifier).setNodeAddress(network, newValue);
      ref.read(walletStateProvider.notifier).reconnect(newValue);
    }
  }

  void _delete(NodeAddress? value) {
    if (value != null) {
      final network = ref.read(settingsProvider).network;
      ref.read(networkNodesProvider.notifier).removeNode(network, value);

      // assuming we want to reconnect to the first available node after deletion
      final nodes = ref.read(networkNodesProvider).getNodes(network);
      if (nodes.isNotEmpty) {
        ref
            .read(networkNodesProvider.notifier)
            .setNodeAddress(network, nodes.first);
        ref.read(walletStateProvider.notifier).reconnect(nodes.first);
      } else {
        ref.read(walletStateProvider.notifier).disconnect();
      }
    }
  }
}
