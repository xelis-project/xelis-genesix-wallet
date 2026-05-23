import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
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
  late String _name = widget.nodeAddress.name;
  late String _url = widget.nodeAddress.url;

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
              control: .managed(
                initial: TextEditingValue(text: widget.nodeAddress.name),
              ),
              label: Text(loc.node_name),
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              onSaved: (value) => _name = value?.trim() ?? '',
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(
                initial: TextEditingValue(text: widget.nodeAddress.url),
              ),
              label: Text(loc.node_url),
              keyboardType: TextInputType.url,
              maxLines: 1,
              autocorrect: false,
              onSaved: (value) => _url = value?.trim() ?? '',
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return loc.node_url_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.large),
            FButton(
              child: Text(loc.save_node),
              onPress: () {
                final form = _formKey.currentState;
                if (form == null || !form.validate()) {
                  return;
                }

                form.save();
                _edit(NodeAddress(name: _name, url: _url));
                context.pop();
              },
            ),
            const SizedBox(height: Spaces.medium),
            FButton(
              variant: .destructive,
              child: Text(loc.delete_node),
              onPress: () {
                _delete();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _edit(NodeAddress newValue) {
    final network = ref.read(settingsProvider).network;
    ref
        .read(networkNodesProvider.notifier)
        .updateNode(network, widget.nodeAddress, newValue);
    unawaited(ref.read(walletRuntimeProvider.notifier).reconnect(newValue));
  }

  void _delete() {
    final network = ref.read(settingsProvider).network;
    ref
        .read(networkNodesProvider.notifier)
        .removeNode(network, widget.nodeAddress);

    // assuming we want to reconnect to the first available node after deletion
    final nodes = ref.read(networkNodesProvider).getNodes(network);
    if (nodes.isNotEmpty) {
      unawaited(
        ref.read(walletRuntimeProvider.notifier).reconnect(nodes.first),
      );
    } else {
      ref
          .read(networkNodesProvider.notifier)
          .setNodeAddress(network, const NodeAddress());
      unawaited(ref.read(walletRuntimeProvider.notifier).disconnect());
    }
  }
}
