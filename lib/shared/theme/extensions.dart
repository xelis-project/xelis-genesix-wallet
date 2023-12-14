import 'package:flutter/material.dart';

extension TypographyUtils on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colors => theme.colorScheme;

  TextStyle? get displayLarge => textTheme.displayLarge;

  TextStyle? get displayMedium => textTheme.displayMedium;

  TextStyle? get displaySmall => textTheme.displaySmall;

  TextStyle? get headlineLarge => textTheme.headlineLarge;

  TextStyle? get headlineMedium => textTheme.headlineMedium;

  TextStyle? get headlineSmall => textTheme.headlineSmall;

  TextStyle? get titleLarge => textTheme.titleLarge;

  TextStyle? get titleMedium => textTheme.titleMedium;

  TextStyle? get titleSmall => textTheme.titleSmall;

  TextStyle? get labelLarge => textTheme.labelLarge;

  TextStyle? get labelMedium => textTheme.labelMedium;

  TextStyle? get labelSmall => textTheme.labelSmall;

  TextStyle? get bodyLarge => textTheme.bodyLarge;

  TextStyle? get bodyMedium => textTheme.bodyMedium;

  TextStyle? get bodySmall => textTheme.bodySmall;

  bool get isDarkMode {
    final brightness = MediaQuery.of(this).platformBrightness;
    return brightness == Brightness.dark;
  }
}

extension BreakpointUtils on BoxConstraints {
  bool get isTablet => maxWidth > 730;

  bool get isDesktop => maxWidth > 1200;

  bool get isMobile => !isTablet && !isDesktop;
}
