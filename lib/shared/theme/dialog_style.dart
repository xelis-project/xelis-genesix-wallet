import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

FDialogStyle dialogStyle({
  required FStyle style,
  required FColors colors,
  required FTypography typography,
  required FHapticFeedback hapticFeedback,
  BuildContext? context,
}) {
  final title = typography.display.lg.copyWith(color: colors.foreground);
  final body = typography.body.sm.copyWith(color: colors.mutedForeground);

  final double insetH;
  final double insetV;
  if (context != null) {
    final mq = context.mediaQueryData;
    final w = mq.size.width;
    final h = mq.size.height;
    insetH = (w * 0.06).clamp(12.0, 40.0);
    insetV = (h * 0.04).clamp(12.0, 24.0);
  } else {
    insetH = 40.0;
    insetV = 24.0;
  }

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
    insetPadding: EdgeInsets.symmetric(horizontal: insetH, vertical: insetV),
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
  final theme = context.theme;
  return showFDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    builder: (ctx, style, animation) => builder(
      ctx,
      dialogStyle(
        style: theme.style,
        colors: theme.colors,
        typography: theme.typography,
        hapticFeedback: theme.hapticFeedback,
        context: ctx,
      ),
      animation,
    ),
  );
}
