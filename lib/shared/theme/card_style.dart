import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Genesix card tokens based on the Forui CLI 0.24 card style.
FCardStyle cardStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required bool touch,
}) => FCardStyle(
  decoration: ShapeDecoration(
    shape: RoundedSuperellipseBorder(
      side: BorderSide(color: colors.border, width: style.borderWidth),
      borderRadius: style.borderRadius.lg,
    ),
    color: colors.card,
  ),
  titleTextStyle: (touch ? typography.display.lg : typography.display.md)
      .copyWith(fontWeight: .w500, color: colors.foreground),
  subtitleTextStyle: typography.body.sm.copyWith(color: colors.mutedForeground),
  padding: const .all(16),
);
