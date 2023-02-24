import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_mobile_wallet/shared/providers/providers.dart';

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
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: () => ref.read(themeModeProvider.notifier).switchThemeMode(),
      icon: _getIcon(isDark),
    );
  }
}
