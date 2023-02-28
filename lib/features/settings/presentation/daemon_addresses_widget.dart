import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_providers.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';

class DaemonAddressesWidget extends ConsumerStatefulWidget {
  const DaemonAddressesWidget({
    super.key,
  });

  @override
  ConsumerState createState() => _DaemonAddressesWidgetState();
}

class _DaemonAddressesWidgetState extends ConsumerState<DaemonAddressesWidget> {
  String? _selectedDaemonAddress;
  late List<String> _daemonAddresses;

  @override
  void initState() {
    super.initState();
    _selectedDaemonAddress = ref.read(daemonAddressSelectedProvider);
    _daemonAddresses = ref.read(daemonAddressesProvider);
  }

  void _onDismissed(int index) {
    if (!AppResources.builtInDaemonAddresses
        .contains(_daemonAddresses[index])) {
      ref
          .read(daemonAddressesProvider.notifier)
          .removeDaemonAddress(_daemonAddresses[index]);
      setState(() {
        _daemonAddresses.removeAt(index);
      });
    }
  }

  void _onDaemonAddressSelected(String? value) {
    setState(() {
      _selectedDaemonAddress = value;
    });
    if (value != null) {
      ref
          .read(daemonAddressSelectedProvider.notifier)
          .selectDaemonAddress(value);
    }
  }

  void _onAddingNewAddressDone(String? value) {
    if (value != null) {
      if (!AppResources.builtInDaemonAddresses.contains(value)) {
        ref.read(daemonAddressesProvider.notifier).addDaemonAddress(value);
        setState(() {
          _daemonAddresses.add(value);
        });
      }
    }
  }

  void _showNewAddressDialog(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'New Daemon Address',
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
            onSaved: _onAddingNewAddressDone,
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
    final daemonAddress = ref.watch(daemonAddressSelectedProvider);
    // final daemonAddresses = ref.watch(daemonAddressesProvider);
    return ExpansionTile(
      title: Text(
        'Daemon Address',
        style: context.titleLarge,
      ),
      subtitle: Text(
        daemonAddress,
        style: context.titleMedium,
      ),
      children: [
        ...List<Dismissible>.generate(
          _daemonAddresses.length,
          (int index) => Dismissible(
            key: ValueKey<String>(_daemonAddresses[index]),
            onDismissed: (direction) {
              _onDismissed(index);
            },
            child: ListTile(
              title: Text(
                _daemonAddresses[index],
                style: context.titleMedium,
              ),
              leading: Radio<String>(
                value: _daemonAddresses[index],
                groupValue: _selectedDaemonAddress,
                onChanged: _onDaemonAddressSelected,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton(
            onPressed: () => _showNewAddressDialog(context),
            child: const Text('Add'),
          ),
        )
      ],
    );
  }
}
