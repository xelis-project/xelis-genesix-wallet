import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class DarkModeSwitchWidget extends ConsumerWidget {
  const DarkModeSwitchWidget({super.key});

  bool _isDarkMode(BuildContext context, ThemeMode themeMode) {
    final isDark = context.theme.brightness == Brightness.dark;

    switch (themeMode) {
      case ThemeMode.system:
        if (isDark) {
          return true;
        } else {
          return false;
        }
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
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
    final loc = ref.watch(appLocalizationsProvider);
    final userThemeMode = ref.watch(userThemeModeProvider);

    return SwitchListTile(
      title: Text(
        loc.dark_mode_setting,
        style: context.titleLarge,
      ),
      value: _isDarkMode(context, userThemeMode.themeMode),
      onChanged: (_) => _changeThemeMode(context, ref),
    );
  }
}
