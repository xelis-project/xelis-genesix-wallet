import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
