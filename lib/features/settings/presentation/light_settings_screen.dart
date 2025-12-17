import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/presentation/components/theme_mode_switcher.dart';
import 'package:genesix/features/settings/presentation/settings_content.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/shared/theme/constants.dart';

class LightSettingsScreen extends StatelessWidget {
  const LightSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.back(onPress: () => context.pop()),
          ),
        ],
        suffixes: [ThemeModeSwitcher()],
      ),
      child: BodyLayoutBuilder(child: SettingsContent()),
    );
  }
}
