import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

extension LegacyInputDecoration on BuildContext {
  InputDecoration get textInputDecoration {
    final base = InputDecorationThemeData(
      isDense: true,
      border: const OutlineInputBorder(),
    );

    return InputDecoration(
      isDense: base.isDense,
      border: base.border,
      enabledBorder: base.enabledBorder ?? base.border,
      focusedBorder: base.focusedBorder ?? base.border,
      errorBorder: base.errorBorder,
      focusedErrorBorder: base.focusedErrorBorder,
      contentPadding:
          base.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: bodyMedium?.copyWith(color: colors.outline),
    );
  }
}
