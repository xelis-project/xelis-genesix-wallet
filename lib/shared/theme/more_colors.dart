import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

extension MoreColors on FColors {
  Color get upColor => Color(0xFF13D38C);

  Color get downColor => Color(0xFFEF4444);

  Color get warningColor => brightness == Brightness.light
      ? const Color(0xFFD97706)
      : const Color(0xFFF5B942);

  Color get warningSurface => warningColor.withValues(
    alpha: brightness == Brightness.light ? 0.12 : 0.18,
  );

  Color get toastSurface => brightness == Brightness.light
      ? card.withValues(alpha: 0.98)
      : Color.lerp(background, secondary, 0.32)!;

  Color get toastBorderColor => brightness == Brightness.light
      ? border.withValues(alpha: 0.92)
      : border.withValues(alpha: 0.96);

  Color get toastShadowColor => brightness == Brightness.light
      ? const Color(0x14030712)
      : const Color(0x52000000);

  Color get toastSubtleSurface => brightness == Brightness.light
      ? secondary.withValues(alpha: 0.7)
      : secondary.withValues(alpha: 0.9);
}
