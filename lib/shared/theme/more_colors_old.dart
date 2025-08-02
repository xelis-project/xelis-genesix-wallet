import 'package:flutter/material.dart';

@immutable
class MoreColors extends ThemeExtension<MoreColors> {
  const MoreColors({
    required this.bgRadialColor1,
    required this.bgRadialColor2,
    required this.bgRadialColor3,
    required this.bgRadialEndColor,
    required this.mutedColor,
  });

  final Color bgRadialColor1;
  final Color bgRadialColor2;
  final Color bgRadialColor3;
  final Color bgRadialEndColor;
  final Color mutedColor;

  @override
  MoreColors copyWith({
    Color? bgRadialColor1,
    Color? bgRadialColor2,
    Color? bgRadialColor3,
    Color? bgRadialEndColor,
    Color? mutedColor,
  }) {
    return MoreColors(
      bgRadialColor1: bgRadialColor1 ?? this.bgRadialColor1,
      bgRadialColor2: bgRadialColor2 ?? this.bgRadialColor2,
      bgRadialColor3: bgRadialColor3 ?? this.bgRadialColor3,
      bgRadialEndColor: bgRadialEndColor ?? this.bgRadialEndColor,
      mutedColor: mutedColor ?? this.mutedColor,
    );
  }

  @override
  MoreColors lerp(MoreColors? other, double t) {
    if (other is! MoreColors) {
      return this;
    }
    return MoreColors(
      bgRadialColor1: Color.lerp(bgRadialColor1, other.bgRadialColor1, t)!,
      bgRadialColor2: Color.lerp(bgRadialColor2, other.bgRadialColor2, t)!,
      bgRadialColor3: Color.lerp(bgRadialColor3, other.bgRadialColor3, t)!,
      bgRadialEndColor: Color.lerp(
        bgRadialEndColor,
        other.bgRadialEndColor,
        t,
      )!,
      mutedColor: Color.lerp(mutedColor, other.mutedColor, t)!,
    );
  }
}
