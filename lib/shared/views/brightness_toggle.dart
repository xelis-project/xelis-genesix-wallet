import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_mobile_wallet/shared/theme/theme_mode.dart';
// import 'package:xelis_mobile_wallet/features/settings/application/settings_service.dart';

class BrightnessToggle extends ConsumerWidget {
  const BrightnessToggle({super.key});

  Icon _getIcon(bool isDark) {
    if (isDark) {
      return const Icon(Icons.dark_mode_outlined);
    } else {
      return const Icon(Icons.light_mode_outlined);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /*final themeMode = ref.watch(themeModeProvider);
    return themeMode.when(
      data: (data) {
        if (data == ThemeMode.dark) {
          return IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {
              ref.read(asyncSettingsProvider.notifier).selectLightMode();
            },
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.light_mode_outlined),
            onPressed: () {
              ref.read(asyncSettingsProvider.notifier).selectDarkMode();
            },
          );
        }
      },
      error: (err, stack) => Text('Error: $err'),
      loading: () => const CircularProgressIndicator(),
    );*/
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: () => ref.read(themeModeProvider.notifier).switchThemeMode(),
      icon: _getIcon(isDark),
    );
  }
}
