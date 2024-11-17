import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
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

  late FocusNode _focusNodeName;
  late FocusNode _focusNodeUrl;

  @override
  void initState() {
    super.initState();
    _focusNodeName = FocusNode();
    _focusNodeUrl = FocusNode();
  }

  @override
  void dispose() {
    _focusNodeName.dispose();
    _focusNodeUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network =
        ref.watch(settingsProvider.select((state) => state.network));
    final networkNodes = ref.watch(networkNodesProvider);
    var nodes = networkNodes.getNodes(network);

    return GenericDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: Spaces.medium, top: Spaces.large),
            child: Text(
              loc.add_new_node_title,
              style: context.titleLarge,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(right: Spaces.small, top: Spaces.small),
            child: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
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
                  focusNode: _focusNodeName,
                  style: context.bodyMedium,
                  autocorrect: false,
                  decoration: context.textInputDecoration.copyWith(
                    labelText: loc.name,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: Spaces.medium),
                FormBuilderTextField(
                  name: 'url',
                  focusNode: _focusNodeUrl,
                  style: context.bodyMedium,
                  autocorrect: false,
                  decoration: context.textInputDecoration.copyWith(
                    labelText: loc.url,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ],
            ),
          ),
        );
      }),
      actions: [
        FilledButton(
          onPressed: () => _addNodeAddress(nodes),
          child: Text(loc.confirm_button),
        ),
      ],
    );
  }

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

    if (nodeAddressFormKey.currentState?.saveAndValidate() ?? false) {
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

      if (name != null && url != null) {
        _unfocusNodes();
        _add(NodeAddress(name: name, url: url));
        context.pop();
      }
    }
  }

  void _unfocusNodes() {
    _focusNodeName.unfocus();
    _focusNodeUrl.unfocus();
  }
}
