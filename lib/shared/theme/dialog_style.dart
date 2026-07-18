import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

FDialogStyle dialogStyle({
  required FStyle style,
  required FColors colors,
  required FTypography typography,
  required FHapticFeedback hapticFeedback,
  required bool touch,
}) {
  final title = (touch ? typography.display.lg : typography.display.md)
      .copyWith(color: colors.foreground);
  final body = typography.body.sm.copyWith(color: colors.mutedForeground);

  return FDialogStyle(
    decoration: BoxDecoration(
      borderRadius: style.borderRadius.md,
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
    titleTextStyle: title,
    bodyTextStyle: body,
    slidePressHapticFeedback: hapticFeedback.selectionClick,
    motion: FDialogMotion(
      fadeInCurve: Curves.easeOutCubic,
      fadeOutCurve: Curves.easeInCubic,
      insetDuration: const Duration(milliseconds: 100),
      insetCurve: Curves.decelerate,
    ),
    insetPadding: touch
        ? const EdgeInsets.all(16)
        : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
  );
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget Function(
    BuildContext context,
    FDialogStyle style,
    Animation<double> animation,
  )
  builder,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
}) {
  return showFDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
