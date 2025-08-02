import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/more_colors_old.dart';
import 'package:go_router/go_router.dart';

extension TypographyUtils on BuildContext {
  TextTheme get textTheme => theme.toApproximateMaterialTheme().textTheme;

  ColorScheme get colors => theme.toApproximateMaterialTheme().colorScheme;

  ScrollBehavior get scrollBehavior => ScrollConfiguration.of(this);

  GoRouterState get goRouterState => GoRouterState.of(this);

  MoreColors get moreColors {
    return Theme.of(this).extension<MoreColors>()!;
  }

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

  double get mediaWidth => MediaQuery.of(this).size.width;

  double get mediaHeight => MediaQuery.of(this).size.height;

  bool get isDarkMode {
    final brightness = mediaQueryData.platformBrightness;
    return brightness == Brightness.dark;
  }
}

bool get isMobileDevice => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

bool get isDesktopDevice =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

enum ScreenSize { small, normal, large, extraLarge, extraExtraLarge }

extension FormFactorUtils on BuildContext {
  ScreenSize get formFactor {
    double deviceWidth = MediaQuery.of(this).size.width;
    if (deviceWidth > 1600) return ScreenSize.extraExtraLarge;
    if (deviceWidth > 900) return ScreenSize.extraLarge;
    if (deviceWidth > 600) return ScreenSize.large;
    if (deviceWidth > 300) return ScreenSize.normal;
    return ScreenSize.small;
  }

  bool get isWideScreen => formFactor == ScreenSize.extraExtraLarge;

  bool get isHandset =>
      formFactor == ScreenSize.small || formFactor == ScreenSize.normal;

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
