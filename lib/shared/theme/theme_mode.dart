import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:xelis_mobile_wallet/features/settings/application/settings_service.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(super.state);

  void switchThemeMode() {
    switch (state) {
      case ThemeMode.system:
        break;
      case ThemeMode.light:
        state = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        state = ThemeMode.light;
        break;
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ThemeMode.light),
);

/*final themeModeProvider = FutureProvider.autoDispose((ref) async {
  final isDarkMode = await ref
      .watch(asyncSettingsProvider.selectAsync((data) => data.isDarkMode));
  if (isDarkMode) {
    return ThemeMode.dark;
  } else {
    return ThemeMode.light;
  }
});*/
