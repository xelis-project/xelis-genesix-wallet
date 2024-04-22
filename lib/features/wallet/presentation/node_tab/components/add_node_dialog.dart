import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';

class AddNodeDialog extends ConsumerStatefulWidget {
  const AddNodeDialog({super.key});

  @override
  ConsumerState<AddNodeDialog> createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends ConsumerState<AddNodeDialog> {
  final nodeAddressFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_nodeAddressFormKey');

  void _add(NodeAddress? value) {
    if (value != null) {
      final settings = ref.read(settingsProvider);
      ref.read(networkNodesProvider.notifier).addNode(settings.network, value);
      // set the newly added node as the current node
      ref.read(walletStateProvider.notifier).reconnect(value);
    }
  }

  void _addNodeAddress(List<NodeAddress> nodes) {
    final loc = ref.read(appLocalizationsProvider);

    final name =
        nodeAddressFormKey.currentState?.fields['name']?.value as String?;
    final url =
        nodeAddressFormKey.currentState?.fields['url']?.value as String?;

    if (name != null && url != null) {
      for (final node in nodes) {
        if (node.name == name) {
          nodeAddressFormKey.currentState?.fields['name']
              ?.invalidate(loc.name_already_exists);
        }
        if (node.url == url) {
          nodeAddressFormKey.currentState?.fields['url']
              ?.invalidate(loc.url_already_exists);
        }
      }

      if (nodeAddressFormKey.currentState?.saveAndValidate() ?? false) {
        _add(NodeAddress(name: name, url: url));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network =
        ref.watch(settingsProvider.select((state) => state.network));
    final networkNodes = ref.watch(networkNodesProvider);
    var nodes = networkNodes.getNodes(network);

    return AlertDialog(
      scrollable: true,
      title: Padding(
        padding: const EdgeInsets.all(Spaces.small),
        child: Text(
          loc.add_new_node_title,
          style: context.titleLarge,
        ),
      ),
      content: Builder(builder: (context) {
        final width = context.mediaSize.width * 0.8;

        return SizedBox(
          width: isDesktopDevice ? width : null,
          child: FormBuilder(
            key: nodeAddressFormKey,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: 'name',
                  style: context.bodyMedium,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: loc.name,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spaces.medium),
                FormBuilderTextField(
                  name: 'url',
                  style: context.bodyMedium,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: loc.url,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      actions: <Widget>[
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(loc.cancel_button),
        ),
        FilledButton(
          onPressed: () => _addNodeAddress(nodes),
          child: Text(loc.ok_button),
        ),
      ],
    );
  }
}
