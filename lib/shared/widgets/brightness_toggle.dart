import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class BrightnessToggle extends ConsumerWidget {
  const BrightnessToggle({super.key});

  Icon _getIcon(BuildContext context, ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        if (context.theme.brightness == Brightness.dark) {
          return const Icon(Icons.light_mode_outlined);
        } else {
          return const Icon(Icons.dark_mode_outlined);
        }
      case ThemeMode.light:
        return const Icon(Icons.dark_mode_outlined);
      case ThemeMode.dark:
        return const Icon(Icons.light_mode_outlined);
    }
  }

  void _changeThemeMode(BuildContext context, WidgetRef ref) {
    if (context.theme.brightness == Brightness.dark) {
      ref.read(userThemeModeProvider.notifier).setThemeMode(ThemeMode.light);
    } else {
      ref.read(userThemeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userThemeMode = ref.watch(userThemeModeProvider);
    return IconButton(
      onPressed: () => _changeThemeMode(context, ref),
      icon: _getIcon(context, userThemeMode.themeMode),
    );
  }
}
