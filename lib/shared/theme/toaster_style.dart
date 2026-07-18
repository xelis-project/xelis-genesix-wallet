import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/more_colors.dart';

FToasterStyle toasterStyle({
  required FColors colors,
  required FTypography typography,
}) {
  // Unlike the generated default, Genesix keeps operational wallet events
  // visible at the top on both touch and desktop layouts.
  final baseRadius = BorderRadius.circular(16);

  return FToasterStyle(
    max: 3,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    expandBehavior: FToasterExpandBehavior.disabled,
    expandStartSpacing: 0,
    expandSpacing: 10,
    collapsedProtrusion: 0,
    collapsedScale: 1,
    motion: const FToasterMotion(
      expandDuration: Duration(milliseconds: 260),
      collapseDuration: Duration(milliseconds: 220),
    ),
    toastAlignment: FToastAlignment.topCenter,
    toastStyles: FToastStyles(
      FVariants(
        FToastStyle(
          constraints: const BoxConstraints(maxWidth: 408, maxHeight: 220),
          decoration: BoxDecoration(
            color: colors.toastSurface,
            border: Border.all(color: colors.toastBorderColor),
            borderRadius: baseRadius,
            boxShadow: [
              BoxShadow(
                color: colors.toastShadowColor,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          iconStyle: IconThemeData(color: colors.foreground, size: 18),
          iconSpacing: 12,
          titleTextStyle: typography.body.sm.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
          titleSpacing: 4,
          descriptionTextStyle: typography.body.xs.copyWith(
            color: colors.mutedForeground,
            height: 1.35,
            overflow: TextOverflow.ellipsis,
          ),
          suffixSpacing: 10,
        ),
        variants: {},
      ),
    ),
  );
}
