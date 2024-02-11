import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/node_addresses_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/node_address.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NodeSelectorWidget extends ConsumerStatefulWidget {
  const NodeSelectorWidget({
    super.key,
  });

  @override
  ConsumerState createState() => NodeSelectorWidgetState();
}

class NodeSelectorWidgetState extends ConsumerState<NodeSelectorWidget> {
  void _onDismissed(int index) {
    final state = ref.read(nodeAddressesProvider);
    ref
        .read(nodeAddressesProvider.notifier)
        .removeNodeAddress(state.nodeAddresses[index]);
  }

  void _onNodeAddressSelected(NodeAddress? value) {
    if (value != null) {
      ref.read(walletStateProvider.notifier).reconnect(value);
    }
  }

  void _addNewAddress(NodeAddress? value) {
    if (value != null) {
      if (!AppResources.builtInNodeAddresses.contains(value)) {
        ref.read(nodeAddressesProvider.notifier).addNodeAddress(value);
      }
    }
  }

  void _showNewAddressDialog(BuildContext context) {
    final nodeAddressFormKey =
        GlobalKey<FormBuilderState>(debugLabel: '_nodeAddressFormKey');

    final nodeAddresses = ref.read(nodeAddressesProvider).nodeAddresses;
    final loc = ref.read(appLocalizationsProvider);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            loc.add_new_node_title,
            style: context.titleLarge,
          ),
        ),
        content: FormBuilder(
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
              const SizedBox(height: 16),
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
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(loc.cancel_button),
          ),
          TextButton(
            onPressed: () {
              final name = nodeAddressFormKey
                  .currentState?.fields['name']?.value as String?;
              final url = nodeAddressFormKey.currentState?.fields['url']?.value
                  as String?;
              if (name != null && url != null) {
                for (final node in nodeAddresses) {
                  if (node.name == name) {
                    nodeAddressFormKey.currentState?.fields['name']
                        ?.invalidate(loc.name_already_exists);
                  }
                  if (node.name == name) {
                    nodeAddressFormKey.currentState?.fields['url']
                        ?.invalidate(loc.url_already_exists);
                  }
                }

                if (nodeAddressFormKey.currentState?.saveAndValidate() ??
                    false) {
                  _addNewAddress(NodeAddress(name: name, url: url));
                  context.pop();
                }
              }
            },
            child: Text(loc.ok_button),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeAddressesProvider);
    final loc = ref.watch(appLocalizationsProvider);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: context.colors.surfaceVariant,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Theme(
        data: context.theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            state.favorite.name,
            style: context.titleLarge,
          ),
          subtitle: Text(
            state.favorite.url,
            style: context.titleSmall,
          ),
          children: [
            ...List<ListTile>.generate(
              AppResources.builtInNodeAddresses.length,
              (index) => ListTile(
                title: Text(
                  AppResources.builtInNodeAddresses[index].name,
                  style: context.bodyLarge,
                ),
                subtitle: Text(
                  AppResources.builtInNodeAddresses[index].url,
                  style: context.bodyMedium,
                ),
                leading: Radio<NodeAddress>(
                  value: AppResources.builtInNodeAddresses[index],
                  groupValue: state.favorite,
                  onChanged: _onNodeAddressSelected,
                ),
              ),
            ),
            ...List<Dismissible>.generate(
              state.nodeAddresses.length,
              (index) => Dismissible(
                key: ValueKey<NodeAddress>(state.nodeAddresses[index]),
                onDismissed: (direction) {
                  _onDismissed(index);
                },
                child: ListTile(
                  title: Text(
                    state.nodeAddresses[index].name,
                    style: context.bodyLarge,
                  ),
                  subtitle: Text(
                    state.nodeAddresses[index].url,
                    style: context.bodyMedium,
                  ),
                  leading: Radio<NodeAddress>(
                    value: state.nodeAddresses[index],
                    groupValue: state.favorite,
                    onChanged: _onNodeAddressSelected,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton(
                onPressed: () => _showNewAddressDialog(context),
                child: Text(
                  loc.add_node_button,
                  style: context.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
