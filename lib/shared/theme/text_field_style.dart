import 'package:flutter/cupertino.dart';
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
  ).ghost;
  final textStyle = typography.sm.copyWith(
    fontFamily: typography.defaultFontFamily,
  );
  return FTextFieldStyle(
    obscureButtonStyle: ghost,
    keyboardAppearance: colors.brightness,
    clearButtonStyle: ghost.copyWith(
      iconContentStyle: ghost.iconContentStyle
          .copyWith(
            iconStyle: FWidgetStateMap({
              WidgetState.disabled: IconThemeData(
                color: colors.disable(colors.mutedForeground),
                size: 17,
              ),
              WidgetState.any: IconThemeData(
                color: colors.mutedForeground,
                size: 17,
              ),
            }),
          )
          .call,
    ),
    contentTextStyle: FWidgetStateMap({
      WidgetState.disabled: textStyle.copyWith(
        color: colors.disable(colors.primary),
      ),
      WidgetState.any: textStyle.copyWith(color: colors.primary),
    }),
    hintTextStyle: FWidgetStateMap({
      WidgetState.disabled: textStyle.copyWith(
        color: colors.disable(colors.border),
      ),
      WidgetState.any: textStyle.copyWith(color: colors.mutedForeground),
    }),
    counterTextStyle: FWidgetStateMap({
      WidgetState.disabled: textStyle.copyWith(
        color: colors.disable(colors.primary),
      ),
      WidgetState.any: textStyle.copyWith(color: colors.primary),
    }),
    border: FWidgetStateMap({
      WidgetState.error: OutlineInputBorder(
        borderSide: BorderSide(color: colors.error, width: style.borderWidth),
        borderRadius: style.borderRadius,
      ),
      WidgetState.disabled: OutlineInputBorder(
        borderSide: BorderSide(
          color: colors.disable(colors.border),
          width: style.borderWidth,
        ),
        borderRadius: style.borderRadius,
      ),
      WidgetState.focused: OutlineInputBorder(
        borderSide: BorderSide(color: colors.primary, width: style.borderWidth),
        borderRadius: style.borderRadius,
      ),
      WidgetState.any: OutlineInputBorder(
        borderSide: BorderSide(color: colors.border, width: style.borderWidth),
        borderRadius: style.borderRadius,
      ),
    }),
    labelTextStyle: FWidgetStateMap({
      WidgetState.error: typography.sm.copyWith(
        color: colors.error,
        fontWeight: FontWeight.w600,
      ),
      WidgetState.disabled: typography.sm.copyWith(
        color: colors.disable(colors.foreground),
        fontWeight: FontWeight.w600,
      ),
      WidgetState.any: typography.sm.copyWith(
        color: colors.foreground,
        fontWeight: FontWeight.w600,
      ),
    }),
    descriptionTextStyle: style.formFieldStyle.descriptionTextStyle,
    errorTextStyle: style.formFieldStyle.errorTextStyle,
    labelPadding: label.labelPadding,
    descriptionPadding: label.descriptionPadding,
    errorPadding: label.errorPadding,
    childPadding: label.childPadding,
    cursorColor: CupertinoColors.activeBlue,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    clearButtonPadding: const EdgeInsetsDirectional.only(end: 4),
    scrollPadding: const EdgeInsets.all(20),
  );
}

FLabelStyles _labelStyles({required FStyle style}) => FLabelStyles(
  horizontalStyle: _labelStyle(
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

FButtonStyles _buttonStyles({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FButtonStyles(
  primary: _buttonStyle(
    colors: colors,
    style: style,
    typography: typography,
    color: colors.primary,
    foregroundColor: colors.primaryForeground,
  ),
  secondary: _buttonStyle(
    colors: colors,
    style: style,
    typography: typography,
    color: colors.secondary,
    foregroundColor: colors.secondaryForeground,
  ),
  destructive: _buttonStyle(
    colors: colors,
    style: style,
    typography: typography,
    color: colors.destructive,
    foregroundColor: colors.destructiveForeground,
  ),
  outline: FButtonStyle(
    decoration: FWidgetStateMap({
      WidgetState.disabled: BoxDecoration(
        border: Border.all(color: colors.disable(colors.border)),
        borderRadius: style.borderRadius,
      ),
      WidgetState.hovered | WidgetState.pressed: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: style.borderRadius,
        color: colors.secondary,
      ),
      WidgetState.any: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: style.borderRadius,
      ),
    }),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: _buttonContentStyle(
      typography: typography,
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    iconContentStyle: _buttonIconContentStyle(
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    tappableStyle: style.tappableStyle,
  ),
  ghost: FButtonStyle(
    decoration: FWidgetStateMap({
      WidgetState.disabled: BoxDecoration(borderRadius: style.borderRadius),
      WidgetState.hovered | WidgetState.pressed: BoxDecoration(
        borderRadius: style.borderRadius,
        color: colors.secondary,
      ),
      WidgetState.any: BoxDecoration(borderRadius: style.borderRadius),
    }),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: _buttonContentStyle(
      typography: typography,
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    iconContentStyle: _buttonIconContentStyle(
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    tappableStyle: style.tappableStyle,
  ),
);

FButtonStyle _buttonStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required Color color,
  required Color foregroundColor,
}) => FButtonStyle(
  decoration: FWidgetStateMap({
    WidgetState.disabled: BoxDecoration(
      borderRadius: style.borderRadius,
      color: colors.disable(color),
    ),
    WidgetState.hovered | WidgetState.pressed: BoxDecoration(
      borderRadius: style.borderRadius,
      color: colors.hover(color),
    ),
    WidgetState.any: BoxDecoration(
      borderRadius: style.borderRadius,
      color: color,
    ),
  }),
  focusedOutlineStyle: style.focusedOutlineStyle,
  contentStyle: _buttonContentStyle(
    typography: typography,
    enabled: foregroundColor,
    disabled: colors.disable(foregroundColor, colors.disable(color)),
  ),
  iconContentStyle: FButtonIconContentStyle(
    iconStyle: FWidgetStateMap({
      WidgetState.disabled: IconThemeData(
        color: colors.disable(foregroundColor, colors.disable(color)),
        size: 20,
      ),
      WidgetState.any: IconThemeData(color: foregroundColor, size: 20),
    }),
  ),
  tappableStyle: style.tappableStyle,
);

FButtonContentStyle _buttonContentStyle({
  required FTypography typography,
  required Color enabled,
  required Color disabled,
}) => FButtonContentStyle(
  circularProgressStyle: FWidgetStateMap({}), // todo maybe
  textStyle: FWidgetStateMap({
    WidgetState.disabled: typography.base.copyWith(
      color: disabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
    WidgetState.any: typography.base.copyWith(
      color: enabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
  }),
  iconStyle: FWidgetStateMap({
    WidgetState.disabled: IconThemeData(color: disabled, size: 20),
    WidgetState.any: IconThemeData(color: enabled, size: 20),
  }),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.5),
  spacing: 10,
);

FButtonIconContentStyle _buttonIconContentStyle({
  required Color enabled,
  required Color disabled,
}) => FButtonIconContentStyle(
  iconStyle: FWidgetStateMap({
    WidgetState.disabled: IconThemeData(color: disabled, size: 20),
    WidgetState.any: IconThemeData(color: enabled, size: 20),
  }),
  padding: const EdgeInsets.all(7.5),
);
