import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/node_addresses_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NodeAddressesWidget extends ConsumerStatefulWidget {
  const NodeAddressesWidget({
    super.key,
  });

  @override
  ConsumerState createState() => NodeAddressesWidgetState();
}

class NodeAddressesWidgetState extends ConsumerState<NodeAddressesWidget> {
  void _onDismissed(int index) {
    final state = ref.read(nodeAddressesProvider);
    ref
        .read(nodeAddressesProvider.notifier)
        .removeNodeAddress(state.nodeAddresses[index]);
  }

  void _onNodeAddressSelected(String? value) {
    if (value != null) {
      ref.read(nodeAddressesProvider.notifier).setFavoriteAddress(value);
    }
  }

  void _onAddingNewAddress(String? value) {
    if (value != null) {
      if (!AppResources.builtInNodeAddresses.contains(value)) {
        ref.read(nodeAddressesProvider.notifier).addNodeAddress(value);
      }
    }
  }

  void _showNewAddressDialog(BuildContext context) {
    ///TODO: add validator with constraints like 'address already exist' etc.
    final formKey =
        GlobalKey<FormBuilderState>(debugLabel: '_nodeAddressFormKey');
    final loc = ref.read(appLocalizationsProvider);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            loc.new_node_address,
            style: context.titleLarge,
          ),
        ),
        content: FormBuilder(
          key: formKey,
          child: FormBuilderTextField(
            name: 'address',
            style: context.bodyMedium,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: loc.address,
              border: const OutlineInputBorder(),
            ),
            onSaved: _onAddingNewAddress,
            onEditingComplete: () {
              formKey.currentState?.save();
              context.pop();
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(loc.cancel_button),
          ),
          TextButton(
            onPressed: () {
              formKey.currentState?.save();
              context.pop();
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
    return ExpansionTile(
      title: Text(
        loc.node_address,
        style: context.titleLarge,
      ),
      subtitle: Text(
        state.favorite,
        style: context.titleMedium,
      ),
      children: [
        ...List<ListTile>.generate(
          AppResources.builtInNodeAddresses.length,
          (index) => ListTile(
            title: Text(
              AppResources.builtInNodeAddresses[index],
              style: context.titleMedium,
            ),
            leading: Radio<String>(
              value: AppResources.builtInNodeAddresses[index],
              groupValue: state.favorite,
              onChanged: _onNodeAddressSelected,
            ),
          ),
        ),
        ...List<Dismissible>.generate(
          state.nodeAddresses.length,
          (index) => Dismissible(
            key: ValueKey<String>(state.nodeAddresses[index]),
            onDismissed: (direction) {
              _onDismissed(index);
            },
            child: ListTile(
              title: Text(
                state.nodeAddresses[index],
                style: context.titleMedium,
              ),
              leading: Radio<String>(
                value: state.nodeAddresses[index],
                groupValue: state.favorite,
                onChanged: _onNodeAddressSelected,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton(
            onPressed: () => _showNewAddressDialog(context),
            child: Text(loc.add_node_button),
          ),
        ),
      ],
    );
  }
}
