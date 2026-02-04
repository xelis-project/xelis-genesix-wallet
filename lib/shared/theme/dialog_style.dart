import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

FDialogStyle dialogStyle({
  required FStyle style,
  required FColors colors,
  required FTypography typography,
  BuildContext? context,
}) {
  final title = typography.lg.copyWith(
    fontWeight: FontWeight.w600,
    color: colors.foreground,
  );
  final body = typography.sm.copyWith(color: colors.mutedForeground);

  final double insetH;
  final double insetV;
  final double contentH;
  final double contentV;

  if (context != null) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final scale = mq.textScaler.scale(1.0);

    insetH = (w * 0.06).clamp(12.0, 40.0);
    insetV = (h * 0.04).clamp(12.0, 24.0);

    contentH = (w * 0.05 / scale).clamp(12.0, 30.0);
    contentV = (w * 0.05 / scale).clamp(12.0, 28.0);
  } else {
    insetH = 40.0;
    insetV = 24.0;
    contentH = 30.0;
    contentV = 25.0;
  }

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
      padding: EdgeInsets.symmetric(horizontal: contentH, vertical: contentV),
      actionSpacing: 7,
    ),
    verticalStyle: FDialogContentStyle(
      titleTextStyle: title,
      bodyTextStyle: body,
      padding: EdgeInsets.symmetric(horizontal: contentH, vertical: contentV),
      actionSpacing: 8,
    ),
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
}) {
  final theme = context.theme;
  return showFDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (ctx, _style, animation) => builder(
      ctx,
      dialogStyle(
        style: theme.style,
        colors: theme.colors,
        typography: theme.typography,
        context: ctx,
      ),
      animation,
    ),
  );
}
