import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

extension TypographyUtils on BuildContext {
  TextTheme get textTheme => theme.toApproximateMaterialTheme().textTheme;

  ColorScheme get colors => theme.toApproximateMaterialTheme().colorScheme;

  ScrollBehavior get scrollBehavior => ScrollConfiguration.of(this);

  GoRouterState get goRouterState => GoRouterState.of(this);

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
}

extension DisplayUtils on BuildContext {
  MediaQueryData get mediaQueryData => MediaQuery.of(this);

  Size get mediaSize => MediaQuery.sizeOf(this);

  double get mediaWidth => mediaSize.width;

  double get mediaHeight => mediaSize.height;

  bool get isDarkMode {
    final brightness = mediaQueryData.platformBrightness;
    return brightness == Brightness.dark;
  }
}

extension FormFactorUtils on BuildContext {
  bool get isWideScreen => mediaWidth >= theme.breakpoints.sm;
  bool get isMobile => !isWideScreen;

  double responsiveDialogMaxWidth({
    double compact = 420,
    double medium = 600,
    double expanded = 720,
  }) {
    final breakpoints = theme.breakpoints;
    final width = mediaWidth;

    if (width < breakpoints.sm) return compact;
    if (width < breakpoints.lg) return medium;
    return expanded;
  }

  double responsiveDialogWidth({
    double min = 280,
    double compact = 420,
    double medium = 600,
    double expanded = 720,
    double viewportRatio = 0.9,
  }) {
    final maxWidth = responsiveDialogMaxWidth(
      compact: compact,
      medium: medium,
      expanded: expanded,
    );

    return math.min(maxWidth, math.max(min, mediaWidth * viewportRatio));
  }

  double responsiveDialogMaxHeight({
    double max = 560,
    double viewportRatio = 0.72,
  }) {
    return math.min(max, mediaHeight * viewportRatio);
  }

  double get getFSheetRatio {
    final breakpoints = theme.breakpoints;
    final width = mediaWidth;

    if (width < breakpoints.sm) {
      // mobile
      return 0.55;
    } else if (width < breakpoints.md) {
      // small tablet
      return 0.50;
    } else if (width < breakpoints.lg) {
      // tablet/large phone landscape
      return 0.45;
    } else if (width < breakpoints.xl) {
      // laptop/desktop
      return 0.40;
    } else if (width < breakpoints.xl2) {
      // very large screen
      return 0.36;
    } else {
      // ultra wide
      return 0.33;
    }
  }
}
