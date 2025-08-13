import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/presentation/settings_navigation_bar/components/xswd_edit_permission_dialog.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget_old.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

class XswdStatusScreen extends ConsumerStatefulWidget {
  const XswdStatusScreen({super.key});

  @override
  ConsumerState createState() => _XswdStatusScreenState();
}

class _XswdStatusScreenState extends ConsumerState<XswdStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final enableXswd = ref.watch(
      settingsProvider.select((settings) => settings.enableXswd),
    );

    final appInfos = ref.watch(xswdApplicationsProvider.future);

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.xswd_status),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spaces.large,
          Spaces.none,
          Spaces.large,
          Spaces.large,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.xwsd_status_screen_message,
              style: context.titleMedium?.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.large),
            // Switch to enable/disable XSWD
            Card(
              child: FormBuilderSwitch(
                name: 'xswd_switch',
                initialValue: enableXswd,
                decoration: const InputDecoration(
                  fillColor: Colors.transparent,
                ),
                title: Text(loc.enable_xswd, style: context.bodyLarge),
                onChanged: _onXswdSwitch,
              ),
            ),
            const SizedBox(height: Spaces.large),
            // List of connected applications
            FutureBuilder(
              future: appInfos,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.error_loading_applications,
                              style: context.titleSmall?.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  final value = snapshot.data as List<AppInfo>;
                  if (value.isEmpty && enableXswd) {
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.no_application_connected,
                                style: context.titleSmall?.copyWith(
                                  color: context.moreColors.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else if (enableXswd) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.applications, style: context.titleMedium),
                        const SizedBox(height: Spaces.small),
                        ...value.map((appInfo) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(Spaces.small),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(appInfo.name),
                                      const SizedBox(height: Spaces.extraSmall),
                                      Text(
                                        appInfo.url ?? '/',
                                        style: context.labelMedium?.copyWith(
                                          color: context.moreColors.mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _onEdit(appInfo),
                                    icon: Icon(Icons.edit, size: 18),
                                  ),
                                  IconButton(
                                    onPressed: () => _onClose(appInfo),
                                    icon: Icon(Icons.delete, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                } else {
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.no_application_found,
                              style: context.titleSmall?.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onXswdSwitch(bool? enabled) {
    if (enabled != null) {
      ref.read(settingsProvider.notifier).setEnableXswd(enabled);
      if (enabled) {
        ref.read(walletStateProvider.notifier).startXSWD();
      } else {
        ref.read(walletStateProvider.notifier).stopXSWD();
      }
    }
  }

  Future<void> _onClose(AppInfo appInfo) async {
    await ref
        .read(walletStateProvider.notifier)
        .closeXswdAppConnection(appInfo);
    ref.invalidate(xswdRequestProvider);
  }

  void _onEdit(AppInfo appInfo) {
    showDialog<void>(
      context: ref.context,
      builder: (context) {
        return XswdEditPermissionDialog(appInfo);
      },
    );
  }
}
