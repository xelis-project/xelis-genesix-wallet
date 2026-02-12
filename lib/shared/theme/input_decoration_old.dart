import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

extension InputDecorationUtils on BuildContext {
  InputDecoration get textInputDecoration => InputDecoration(
    errorMaxLines: 2,
    labelStyle: labelLarge?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: colors.onSurface.withValues(alpha: 0.5),
        width: 2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.onSurface, width: 2),
    ),
  );
}
