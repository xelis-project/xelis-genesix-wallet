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

class AddNodeSheet extends ConsumerStatefulWidget {
  const AddNodeSheet({super.key});

  @override
  ConsumerState<AddNodeSheet> createState() => _AddNodeSheetState();
}

class _AddNodeSheetState extends ConsumerState<AddNodeSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _name = '';
  String _url = '';

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
              label: Text(loc.node_name),
              hint: loc.node_name_hint,
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
              label: Text(loc.node_url),
              hint: loc.node_url_hint,
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
              child: Text(loc.add_node),
              onPress: () => _addNodeAndReconnect(context),
            ),
          ],
        ),
      ),
    );
  }

  void _addNodeAndReconnect(BuildContext context) {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    form.save();
    final node = NodeAddress(name: _name, url: _url);
    final network = ref.read(settingsProvider).network;
    ref.read(networkNodesProvider.notifier).addNode(network, node);
    unawaited(ref.read(walletRuntimeProvider.notifier).reconnect(node));
    context.pop();
  }
}
