import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:forui/forui.dart';

FTextFieldSizeStyles textFieldStyles({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required bool touch,
}) {
  final label = _labelStyles(style: style).verticalStyle;
  final ghost = FButtonStyles.inherit(
    colors: colors,
    typography: typography,
    style: style,
    touch: touch,
  ).ghost.sm;
  final textStyle = typography.sm.copyWith(fontFamily: typography.fontFamily);
  final iconStyle =
      FVariants<
        FTextFieldVariantConstraint,
        FTextFieldVariant,
        IconThemeData,
        IconThemeDataDelta
      >.from(
        IconThemeData(
          color: colors.mutedForeground,
          size: typography.sm.fontSize,
        ),
        variants: {
          [.disabled]: .delta(color: colors.disable(colors.mutedForeground)),
        },
      );

  return FTextFieldSizeStyles(
    FVariants.all(
      FTextFieldStyle.inherit(
        colors: colors,
        style: style,
        labelStyle: label,
        textStyle: textStyle,
        iconStyle: iconStyle,
        buttonStyle: ghost.copyWith(
          iconContentStyle: ghost.iconContentStyle.copyWith(
            iconStyle: iconStyle.cast(),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ).copyWith(cursorColor: CupertinoColors.activeBlue),
    ),
  );
}

FLabelStyles _labelStyles({required FStyle style}) => FLabelStyles(
  horizontalLeadingStyle: _labelStyle(
    style: style,
    descriptionPadding: const EdgeInsets.only(top: 2),
    errorPadding: const EdgeInsets.only(top: 2),
    childPadding: const EdgeInsets.symmetric(horizontal: 8),
  ),
  horizontalTrailingStyle: _labelStyle(
    style: style,
    descriptionPadding: const EdgeInsets.only(top: 2),
    errorPadding: const EdgeInsets.only(top: 2),
    childPadding: const EdgeInsets.symmetric(horizontal: 8),
  ),
  verticalStyle: _labelStyle(
    style: style,
    labelPadding: const EdgeInsets.only(bottom: 5),
    descriptionPadding: const EdgeInsets.only(top: 5),
    errorPadding: const EdgeInsets.only(top: 5),
  ),
);

FLabelStyle _labelStyle({
  required FStyle style,
  EdgeInsetsGeometry labelPadding = EdgeInsets.zero,
  EdgeInsetsGeometry descriptionPadding = EdgeInsets.zero,
  EdgeInsetsGeometry errorPadding = EdgeInsets.zero,
  EdgeInsetsGeometry childPadding = EdgeInsets.zero,
}) => FLabelStyle.inherit(
  style: style,
  labelPadding: labelPadding,
  descriptionPadding: descriptionPadding,
  errorPadding: errorPadding,
  childPadding: childPadding,
);
