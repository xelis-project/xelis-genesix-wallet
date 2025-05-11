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

class ModifyNodeDialog extends ConsumerStatefulWidget {
  const ModifyNodeDialog(this.oldNodeAddress, {super.key});

  final NodeAddress oldNodeAddress;

  @override
  ConsumerState<ModifyNodeDialog> createState() => _ModifyNodeDialogState();
}

class _ModifyNodeDialogState extends ConsumerState<ModifyNodeDialog> {
  final nodeAddressFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_nodeAddressFormKey',
  );

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
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final networkNodes = ref.watch(networkNodesProvider);
    var nodes = networkNodes.getNodes(network);

    return GenericDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  loc.edit_node,
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Builder(
        builder: (context) {
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
                    initialValue: widget.oldNodeAddress.name,
                    style: context.bodyMedium,
                    autocorrect: false,
                    decoration: context.textInputDecoration.copyWith(
                      labelText: loc.name,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                  ),
                  const SizedBox(height: Spaces.medium),
                  FormBuilderTextField(
                    name: 'url',
                    focusNode: _focusNodeUrl,
                    initialValue: widget.oldNodeAddress.url,
                    style: context.bodyMedium,
                    autocorrect: false,
                    decoration: context.textInputDecoration.copyWith(
                      labelText: loc.url,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        FilledButton(
          onPressed: () => _modifyNodeAddress(nodes),
          child: Text(loc.confirm_button),
        ),
      ],
    );
  }

  void _modify(NodeAddress? newValue) {
    if (newValue != null) {
      final settings = ref.read(settingsProvider);
      ref
          .read(networkNodesProvider.notifier)
          .updateNode(settings.network, widget.oldNodeAddress, newValue);
      // set the newly added node as the current node
      ref.read(walletStateProvider.notifier).reconnect(newValue);
    }
  }

  void _modifyNodeAddress(List<NodeAddress> nodes) {
    final loc = ref.read(appLocalizationsProvider);

    final name =
        nodeAddressFormKey.currentState?.fields['name']?.value as String?;
    final url =
        nodeAddressFormKey.currentState?.fields['url']?.value as String?;

    if (nodeAddressFormKey.currentState?.saveAndValidate() ?? false) {
      for (final node in nodes) {
        if (node.name == name) {
          nodeAddressFormKey.currentState?.fields['name']?.invalidate(
            loc.name_already_exists,
          );
        }
        if (node.url == url) {
          nodeAddressFormKey.currentState?.fields['url']?.invalidate(
            loc.url_already_exists,
          );
        }
      }

      if (name != null && url != null) {
        _unfocusNodes();
        _modify(NodeAddress(name: name, url: url));
        context.pop();
      }
    }
  }

  void _unfocusNodes() {
    _focusNodeName.unfocus();
    _focusNodeUrl.unfocus();
  }
}
