import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Compatibility accessors for widgets that still use Material typography.
///
/// New Forui UI should use [theme] directly. This extension can disappear once
/// the remaining Material surfaces have been migrated.
extension MaterialThemeUtils on BuildContext {
  TextTheme get _materialTextTheme =>
      theme.toApproximateMaterialTheme().textTheme;

  TextStyle? get headlineSmall => _materialTextTheme.headlineSmall;

  TextStyle? get titleMedium => _materialTextTheme.titleMedium;

  TextStyle? get titleSmall => _materialTextTheme.titleSmall;

  TextStyle? get labelLarge => _materialTextTheme.labelLarge;

  TextStyle? get labelMedium => _materialTextTheme.labelMedium;

  TextStyle? get labelSmall => _materialTextTheme.labelSmall;

  TextStyle? get bodyLarge => _materialTextTheme.bodyLarge;

  TextStyle? get bodyMedium => _materialTextTheme.bodyMedium;

  TextStyle? get bodySmall => _materialTextTheme.bodySmall;
}

extension ScrollUtils on BuildContext {
  ScrollBehavior get scrollBehavior => ScrollConfiguration.of(this);
}

extension RouterUtils on BuildContext {
  GoRouterState get goRouterState => GoRouterState.of(this);
}

extension ViewportUtils on BuildContext {
  double get viewportWidth => MediaQuery.sizeOf(this).width;

  double get viewportHeight => MediaQuery.sizeOf(this).height;
}

extension LayoutUtils on BuildContext {
  bool get isWideLayout => viewportWidth >= theme.breakpoints.sm;
  bool get isCompactLayout => !isWideLayout;

  double responsiveDialogMaxWidth({
    double compact = 420,
    double medium = 600,
    double expanded = 720,
  }) {
    final breakpoints = theme.breakpoints;
    final width = viewportWidth;

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

    return math.min(maxWidth, math.max(min, viewportWidth * viewportRatio));
  }

  double responsiveDialogMaxHeight({
    double max = 560,
    double viewportRatio = 0.72,
  }) {
    return math.min(max, viewportHeight * viewportRatio);
  }

  double get responsiveSheetMaxRatio {
    final breakpoints = theme.breakpoints;
    final width = viewportWidth;

    if (width < breakpoints.sm) {
      // Compact layout.
      return 0.55;
    } else if (width < breakpoints.md) {
      // Medium layout.
      return 0.50;
    } else if (width < breakpoints.lg) {
      // Expanded layout.
      return 0.45;
    } else if (width < breakpoints.xl) {
      // Large layout.
      return 0.40;
    } else if (width < breakpoints.xl2) {
      // Extra-large layout.
      return 0.36;
    } else {
      // Ultra-wide layout.
      return 0.33;
    }
  }
}
