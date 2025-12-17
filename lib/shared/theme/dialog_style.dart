import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:forui/forui.dart';

FDialogStyle dialogStyle({
  required FStyle style,
  required FColors colors,
  required FTypography typography,
}) {
  final title = typography.lg.copyWith(
    fontWeight: FontWeight.w600,
    color: colors.foreground,
  );
  final body = typography.sm.copyWith(color: colors.mutedForeground);
  return FDialogStyle(
    decoration: BoxDecoration(
      borderRadius: style.borderRadius,
      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      color: colors.background,
      boxShadow: [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.2),
          blurRadius: 200,
          spreadRadius: 20,
        ),
      ],
    ),
    horizontalStyle: FDialogContentStyle(
      titleTextStyle: title,
      bodyTextStyle: body,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      actionSpacing: 7,
    ),
    verticalStyle: FDialogContentStyle(
      titleTextStyle: title,
      bodyTextStyle: body,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      actionSpacing: 8,
    ),
    motion: FDialogMotion(
      //entranceExitDuration: const Duration(milliseconds: 150),
      fadeInCurve: Curves.easeOutCubic,
      fadeOutCurve: Curves.easeInCubic,
      insetDuration: const Duration(milliseconds: 100),
      insetCurve: Curves.decelerate,
    ),
    insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
  );
}
