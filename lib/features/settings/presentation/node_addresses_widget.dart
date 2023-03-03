import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_providers.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';

class NodeAddressesWidget extends ConsumerStatefulWidget {
  const NodeAddressesWidget({
    super.key,
  });

  @override
  ConsumerState createState() => NodeAddressesWidgetState();
}

class NodeAddressesWidgetState extends ConsumerState<NodeAddressesWidget> {
  String? _selectedNodeAddress;
  late List<String> _nodeAddresses;

  @override
  void initState() {
    super.initState();
    _selectedNodeAddress = ref.read(nodeAddressSelectedProvider);
    _nodeAddresses = ref.read(nodeAddressesProvider);
  }

  void _onDismissed(int index) {
    if (!AppResources.builtInNodeAddresses.contains(_nodeAddresses[index])) {
      ref
          .read(nodeAddressesProvider.notifier)
          .removeNodeAddress(_nodeAddresses[index]);
      setState(() {
        _nodeAddresses.removeAt(index);
      });
    }
  }

  void _onNodeAddressSelected(String? value) {
    setState(() {
      _selectedNodeAddress = value;
    });
    if (value != null) {
      ref.read(nodeAddressSelectedProvider.notifier).selectNodeAddress(value);
    }
  }

  void _onAddingNewAddress(String? value) {
    if (value != null) {
      if (!AppResources.builtInNodeAddresses.contains(value)) {
        ref.read(nodeAddressesProvider.notifier).addNodeAddress(value);
        setState(() {
          _nodeAddresses.add(value);
        });
      }
    }
  }

  void _showNewAddressDialog(BuildContext context) {
    final formKey =
        GlobalKey<FormBuilderState>(debugLabel: '_nodeAddressFormKey');
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'New Node Address',
          style: context.titleLarge,
        ),
        content: FormBuilder(
          key: formKey,
          child: FormBuilderTextField(
            name: 'address',
            style: context.bodyMedium,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            onSaved: _onAddingNewAddress,
            onEditingComplete: () {
              formKey.currentState?.save();
              context.pop();
            },
            // validator: FormBuilderValidators.ip(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              formKey.currentState?.save();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodeAddress = ref.watch(nodeAddressSelectedProvider);
    final loc = ref.watch(appLocalizationsProvider);
    return ExpansionTile(
      title: Text(
        loc.node_address,
        style: context.titleLarge,
      ),
      subtitle: Text(
        nodeAddress,
        style: context.titleMedium,
      ),
      children: [
        ...List<Dismissible>.generate(
          _nodeAddresses.length,
          (int index) => Dismissible(
            key: ValueKey<String>(_nodeAddresses[index]),
            onDismissed: (direction) {
              _onDismissed(index);
            },
            child: ListTile(
              title: Text(
                _nodeAddresses[index],
                style: context.titleMedium,
              ),
              leading: Radio<String>(
                value: _nodeAddresses[index],
                groupValue: _selectedNodeAddress,
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
        )
      ],
    );
  }
}
