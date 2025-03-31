import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/presentation/settings_tab/components/xswd_edit_permission_dialog.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';

class XswdStatusScreen extends ConsumerStatefulWidget {
  const XswdStatusScreen({super.key});

  @override
  ConsumerState createState() => _XswdStatusScreenState();
}

class _XswdStatusScreenState extends ConsumerState<XswdStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final enableXswd = ref.watch(
      settingsProvider.select((settings) => settings.enableXswd),
    );

    final appInfos = ref.watch(xswdApplicationsProvider.future);

    return CustomScaffold(
      appBar: GenericAppBar(title: 'XSWD Status'),
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
              'Manage application permissions with XSWD protocol.',
              style: context.titleMedium?.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.large),
            Card(
              child: FormBuilderSwitch(
                name: 'xswd_switch',
                initialValue: enableXswd,
                decoration: const InputDecoration(
                  fillColor: Colors.transparent,
                ),
                title: Text('Enable XSWD protocol', style: context.bodyLarge),
                onChanged: _onXswdSwitch,
              ),
            ),
            const SizedBox(height: Spaces.large),
            Text('Applications:', style: context.titleMedium),
            const SizedBox(height: Spaces.small),
            // applications,
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
                              'Error loading applications',
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
                if (snapshot.hasData) {
                  final value = snapshot.data as List<AppInfo>;
                  if (value.isEmpty) {
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No connected applications',
                                style: context.titleSmall?.copyWith(
                                  color: context.moreColors.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      children:
                          value.map((appInfo) {
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
                                        const SizedBox(
                                          height: Spaces.extraSmall,
                                        ),
                                        Text(
                                          appInfo.url ?? '/',
                                          style: context.labelMedium?.copyWith(
                                            color:
                                                context.moreColors.mutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _onEdit(appInfo),
                                      icon: Icon(Icons.edit, size: 18),
                                    ),
                                    // const SizedBox(width: Spaces.small),
                                    IconButton(
                                      onPressed: () => _onClose(appInfo),
                                      icon: Icon(Icons.delete, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  }
                }
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No applications found',
                            style: context.titleSmall?.copyWith(
                              color: context.moreColors.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
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
