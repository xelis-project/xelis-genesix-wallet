import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_providers.dart';

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
    final isDark = ref.watch(darkModeProvider);
    return IconButton(
      onPressed: () => ref.read(darkModeProvider.notifier).switchState(),
      icon: _getIcon(isDark),
    );
  }
}
