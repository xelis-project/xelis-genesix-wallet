import 'package:flutter/material.dart';

import 'package:forui/forui.dart';

FTextFieldStyle textFieldStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) {
  final label = _labelStyles(style: style).verticalStyle;
  final ghost = _buttonStyles(
    colors: colors,
    typography: typography,
    style: style,
  ).ghost.sm;
  final textStyle = typography.sm.copyWith(
    fontFamily: typography.defaultFontFamily,
  );
  final iconStyle =
      FVariants<
        FTextFieldVariantConstraint,
        FTextFieldVariant,
        IconThemeData,
        IconThemeDataDelta
      >.from(
        IconThemeData(color: colors.mutedForeground, size: 16),
        variants: {
          [.disabled]: .delta(color: colors.disable(colors.mutedForeground)),
        },
      );
  final bounceableButtonStyle = ghost.copyWith(
    iconContentStyle: ghost.iconContentStyle.copyWith(
      iconStyle: iconStyle.cast(),
    ),
  );
  return .new(
    keyboardAppearance: colors.brightness,
    color: FVariants(
      colors.card,
      variants: {
        [.disabled]: colors.disable(colors.card),
      },
    ),
    cursorColor: colors.primary,
    iconStyle: iconStyle,
    clearButtonStyle: bounceableButtonStyle,
    obscureButtonStyle: bounceableButtonStyle.copyWith(
      tappableStyle: const .delta(
        motion: .delta(bounceTween: FTappableMotion.noBounceTween),
      ),
    ),
    contentTextStyle: FVariants.from(
      textStyle.copyWith(color: colors.foreground),
      variants: {
        [.disabled]: .delta(color: colors.disable(colors.foreground)),
      },
    ),
    hintTextStyle: FVariants.from(
      textStyle.copyWith(color: colors.mutedForeground),
      variants: {
        [.disabled]: .delta(color: colors.disable(colors.mutedForeground)),
      },
    ),
    counterTextStyle: FVariants.from(
      textStyle.copyWith(color: colors.foreground),
      variants: {
        [.disabled]: .delta(color: colors.disable(colors.foreground)),
      },
    ),
    border: FVariants(
      OutlineInputBorder(
        borderSide: BorderSide(color: colors.border, width: style.borderWidth),
        borderRadius: style.borderRadius,
      ),
      variants: {
        [.focused]: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.primary,
            width: style.borderWidth,
          ),
          borderRadius: style.borderRadius,
        ),
        [.disabled]: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.disable(colors.border),
            width: style.borderWidth,
          ),
          borderRadius: style.borderRadius,
        ),
        [.error]: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error, width: style.borderWidth),
          borderRadius: style.borderRadius,
        ),
        [.error.and(.disabled)]: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.disable(colors.error),
            width: style.borderWidth,
          ),
          borderRadius: style.borderRadius,
        ),
      },
    ),
    labelTextStyle: style.formFieldStyle.labelTextStyle,
    descriptionTextStyle: style.formFieldStyle.descriptionTextStyle,
    errorTextStyle: style.formFieldStyle.errorTextStyle,
    labelPadding: label.labelPadding,
    descriptionPadding: label.descriptionPadding,
    errorPadding: label.errorPadding,
    childPadding: label.childPadding,
  );
}

FLabelStyles _labelStyles({required FStyle style}) => FLabelStyles(
  horizontalStyle: .inherit(
    style: style,
    descriptionPadding: const .only(top: 2),
    errorPadding: const .only(top: 2),
    childPadding: const .symmetric(horizontal: 8),
  ),
  verticalStyle: .inherit(
    style: style,
    labelPadding: const .only(bottom: 5),
    descriptionPadding: const .only(top: 5),
    errorPadding: const .only(top: 5),
  ),
);

FButtonStyles _buttonStyles({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FButtonStyles(
  FVariants(
    _buttonSizeStyles(
      typography: typography,
      style: style,
      decoration: .from(
        BoxDecoration(borderRadius: style.borderRadius, color: colors.primary),
        variants: {
          [.hovered, .pressed]: .delta(color: colors.hover(colors.primary)),
          [.disabled]: .delta(color: colors.disable(colors.primary)),
          [.selected]: .delta(color: colors.hover(colors.primary)),
          [.selected.and(.disabled)]: .delta(
            color: colors.disable(colors.hover(colors.primary)),
          ),
        },
      ),
      foregroundColor: colors.primaryForeground,
      disabledForegroundColor: colors.disable(colors.primaryForeground),
    ),
    variants: {
      [.secondary]: _buttonSizeStyles(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(
            borderRadius: style.borderRadius,
            color: colors.secondary,
          ),
          variants: {
            [.hovered, .pressed]: .delta(color: colors.hover(colors.secondary)),
            [.disabled]: .delta(color: colors.disable(colors.secondary)),
            [.selected]: .delta(color: colors.hover(colors.secondary)),
            [.selected.and(.disabled)]: .delta(
              color: colors.disable(colors.hover(colors.secondary)),
            ),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
      ),
      [.destructive]: _buttonSizeStyles(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(
            borderRadius: style.borderRadius,
            color: colors.destructive.withValues(
              alpha: colors.brightness == .light ? 0.1 : 0.2,
            ),
          ),
          variants: {
            [.hovered, .pressed]: .delta(
              color: colors.destructive.withValues(
                alpha: colors.brightness == .light ? 0.2 : 0.3,
              ),
            ),
            [.disabled]: .delta(
              color: colors.destructive.withValues(
                alpha: colors.brightness == .light ? 0.05 : 0.1,
              ),
            ),
            [.selected]: .delta(
              color: colors.destructive.withValues(
                alpha: colors.brightness == .light ? 0.2 : 0.3,
              ),
            ),
            [.selected.and(.disabled)]: .delta(
              color: colors.disable(
                colors.destructive.withValues(
                  alpha: colors.brightness == .light ? 0.2 : 0.3,
                ),
              ),
            ),
          },
        ),
        foregroundColor: colors.destructive,
        disabledForegroundColor: colors.destructive.withValues(alpha: 0.5),
      ),
      [.outline]: _buttonSizeStyles(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(
            border: .all(color: colors.border),
            borderRadius: style.borderRadius,
            color: colors.card,
          ),
          variants: {
            [.hovered, .pressed]: .delta(color: colors.secondary),
            [.disabled]: .delta(color: colors.disable(colors.card)),
            [.selected]: .delta(color: colors.secondary),
            [.selected.and(.disabled)]: .delta(
              color: colors.disable(colors.secondary),
            ),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
      ),
      [.ghost]: _buttonSizeStyles(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(borderRadius: style.borderRadius),
          variants: {
            [.hovered, .pressed]: .delta(color: colors.secondary),
            [.disabled]: const .delta(),
            [.selected]: .delta(color: colors.secondary),
            [.selected.and(.disabled)]: .delta(
              color: colors.disable(colors.secondary),
            ),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
      ),
    },
  ),
);

FButtonSizeStyles _buttonSizeStyles({
  required FTypography typography,
  required FStyle style,
  required FVariants<
    FTappableVariantConstraint,
    FTappableVariant,
    BoxDecoration,
    BoxDecorationDelta
  >
  decoration,
  required Color foregroundColor,
  required Color disabledForegroundColor,
}) {
  FButtonStyle button({
    required TextStyle textStyle,
    required EdgeInsetsGeometry contentPadding,
    required double contentSpacing,
    required double iconSize,
    required EdgeInsetsGeometry iconPadding,
  }) => FButtonStyle(
    decoration: decoration,
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: FButtonContentStyle(
      textStyle: .from(
        textStyle.copyWith(
          color: foregroundColor,
          fontWeight: .w500,
          height: 1,
          leadingDistribution: .even,
        ),
        variants: {
          [.disabled]: .delta(color: disabledForegroundColor),
        },
      ),
      iconStyle: .from(
        IconThemeData(color: foregroundColor, size: iconSize),
        variants: {
          [.disabled]: .delta(color: disabledForegroundColor),
        },
      ),
      circularProgressStyle: .from(
        FCircularProgressStyle(
          iconStyle: IconThemeData(color: foregroundColor, size: iconSize),
        ),
        variants: {
          [.disabled]: .delta(
            iconStyle: .delta(color: disabledForegroundColor),
          ),
        },
      ),
      padding: contentPadding,
      spacing: contentSpacing,
    ),
    iconContentStyle: FButtonIconContentStyle(
      iconStyle: .from(
        IconThemeData(color: foregroundColor, size: iconSize),
        variants: {
          [.disabled]: .delta(color: disabledForegroundColor),
        },
      ),
      padding: iconPadding,
    ),
    tappableStyle: style.tappableStyle,
  );
  return FButtonSizeStyles(
    FVariants(
      button(
        textStyle: typography.base,
        contentPadding: const .symmetric(horizontal: 16, vertical: 11),
        contentSpacing: 10,
        iconSize: typography.base.fontSize ?? 16,
        iconPadding: const .all(11),
      ),
      variants: {
        [.xs]: button(
          textStyle: typography.xs,
          contentPadding: const .symmetric(horizontal: 8, vertical: 7),
          contentSpacing: 6,
          iconSize: typography.xs.fontSize ?? 12,
          iconPadding: const .all(7),
        ),
        [.sm]: button(
          textStyle: typography.sm,
          contentPadding: const .symmetric(horizontal: 12, vertical: 9),
          contentSpacing: 8,
          iconSize: typography.sm.fontSize ?? 14,
          iconPadding: const .all(9),
        ),
        [.lg]: button(
          textStyle: typography.base,
          contentPadding: const .symmetric(horizontal: 32, vertical: 14),
          contentSpacing: 10,
          iconSize: typography.base.fontSize ?? 16,
          iconPadding: const .all(14),
        ),
      },
    ),
  );
}
