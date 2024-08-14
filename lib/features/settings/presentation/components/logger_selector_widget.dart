import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';

class LoggerSelectorWidget extends ConsumerWidget {
  const LoggerSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final activateLogger =
        ref.watch(settingsProvider.select((state) => state.activateLogger));
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: Border.all(color: Colors.transparent, width: 0),
      collapsedShape: Border.all(color: Colors.transparent, width: 0),
      title: Text(
        loc.advanced_parameters,
        style: context.titleLarge,
      ),
      children: [
        FormBuilderSwitch(
          name: 'activate_logger_switch',
          initialValue: activateLogger,
          decoration: const InputDecoration(fillColor: Colors.transparent),
          title: Text(loc.activate_logger, style: context.bodyLarge),
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setActivateLogger(value!);
          },
        ),
      ],
    );
  }
}
