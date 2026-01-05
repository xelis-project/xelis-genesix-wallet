import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/presentation/settings_navigation_bar/components/xswd_edit_permission_dialog.dart';
import 'package:genesix/features/wallet/presentation/settings_navigation_bar/components/xswd_qr_scanner_screen.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spaces.large,
                Spaces.none,
                Spaces.large,
                Spaces.none,
              ),
              child: ListView(
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
            if (enableXswd)
              FutureBuilder(
                future: appInfos,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spaces.large),
                      child: Text(
                        loc.error_loading_applications,
                        style: context.titleSmall?.copyWith(
                          color: context.moreColors.mutedColor,
                        ),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final value = snapshot.data as List<AppInfo>;
                    if (value.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: Spaces.large),
                        child: Text(
                          loc.no_application_connected,
                          style: context.titleSmall?.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                      );
                    } else {
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  appInfo.name,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (appInfo.isRelayer) ...[
                                                const SizedBox(width: Spaces.extraSmall),
                                                Icon(
                                                  Icons.cloud_outlined,
                                                  size: 16,
                                                  color: context.moreColors.mutedColor,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: Spaces.extraSmall),
                                          Text(
                                            appInfo.url ?? '/',
                                            style: context.labelMedium?.copyWith(
                                              color: context.moreColors.mutedColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
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
                    }
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
                ],
              ),
            ),
          ),
          // Footer with "New Connection" button
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.theme.colors.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(Spaces.large),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onNewConnection,
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text('New Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.colors.primary,
              foregroundColor: context.theme.colors.primaryForeground,
              padding: const EdgeInsets.symmetric(
                vertical: Spaces.medium,
                horizontal: Spaces.large,
              ),
            ),
          ),
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

  Future<void> _onNewConnection() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const XswdQRScannerScreen(),
      ),
    );
  }
}
