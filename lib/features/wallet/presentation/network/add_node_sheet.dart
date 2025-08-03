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

class AddNodeSheet extends ConsumerStatefulWidget {
  const AddNodeSheet({super.key});

  @override
  ConsumerState<AddNodeSheet> createState() => _AddNodeSheetState();
}

class _AddNodeSheetState extends ConsumerState<AddNodeSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

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
              label: Text('Node Name'),
              hint: 'My Node',
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
              label: Text('URL'),
              hint: 'https://example.com',
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                if (!Uri.tryParse(value)!.hasScheme) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.large),
            FButton(
              child: Text('Add Node'),
              onPress: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _add(
                    NodeAddress(
                      name: _nameController.text,
                      url: _urlController.text,
                    ),
                  );
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _add(NodeAddress? value) {
    if (value != null) {
      final network = ref.read(settingsProvider).network;
      ref.read(networkNodesProvider.notifier).addNode(network, value);
      // set the newly added network as the current network
      ref.read(networkNodesProvider.notifier).setNodeAddress(network, value);
      ref.read(walletStateProvider.notifier).reconnect(value);
    }
  }
}
