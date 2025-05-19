import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:go_router/go_router.dart';

class XswdEditPermissionDialog extends ConsumerStatefulWidget {
  const XswdEditPermissionDialog(this.appInfo, {super.key});

  final AppInfo appInfo;

  @override
  ConsumerState createState() => _XswdEditPermissionDialogState();
}

class _XswdEditPermissionDialogState
    extends ConsumerState<XswdEditPermissionDialog> {
  late Map<String, PermissionPolicy> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = Map.from(widget.appInfo.permissions);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.read(appLocalizationsProvider);
    ref.listen(xswdRequestProvider, (previous, next) {
      if (next.xswdEventSummary?.isAppDisconnect() ?? false) {
        context.pop();
      }
    });
    return GenericDialog(
      scrollable: false,
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
                  loc.edit_permissions,
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
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
      content: Container(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.id.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            SelectableText(widget.appInfo.id, style: context.bodyLarge),
            const SizedBox(height: Spaces.medium),
            Text(
              loc.name.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            SelectableText(widget.appInfo.name, style: context.bodyLarge),
            const SizedBox(height: Spaces.medium),
            if (widget.appInfo.url != null) ...[
              Text(
                loc.url.capitalize(),
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              SelectableText(widget.appInfo.url!, style: context.bodyLarge),
              const SizedBox(height: Spaces.medium),
            ],
            Text(
              loc.description.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            SelectableText(widget.appInfo.description, style: context.bodyLarge),
            const SizedBox(height: Spaces.medium),
            Text(
              loc.permissions.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children:
                    _permissions.entries
                        .map(
                          (entry) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(Spaces.small),
                              child: Row(
                                children: [
                                  Chip(
                                    label: Text(entry.key),
                                    avatar: Icon(Icons.code, size: 16),
                                  ),
                                  context.isHandset
                                      ? const SizedBox(width: Spaces.medium)
                                      : Spacer(),
                                  Expanded(
                                    child: GenericFormBuilderDropdown<
                                      PermissionPolicy
                                    >(
                                      initialValue: entry.value,
                                      dropdownColor: Colors.black,
                                      name: 'permission_${entry.key}',
                                      items: [
                                        DropdownMenuItem(
                                          value: PermissionPolicy.ask,
                                          child: Text(loc.ask),
                                        ),
                                        DropdownMenuItem(
                                          value: PermissionPolicy.accept,
                                          child: Text(loc.allow),
                                        ),
                                        DropdownMenuItem(
                                          value: PermissionPolicy.reject,
                                          child: Text(loc.deny),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        _permissions[entry.key] = value!;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: _onSave, child: Text(loc.save))],
    );
  }

  void _onSave() {
    ref
        .read(walletStateProvider.notifier)
        .editXswdAppPermission(widget.appInfo.id, _permissions);
    context.pop();
    ref.invalidate(xswdRequestProvider);
  }
}
