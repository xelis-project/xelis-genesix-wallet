import 'package:forui/forui.dart';

/// Uses Forui's canonical 0.24 text-field tokens, including distinct compact
/// desktop and touch-friendly size constraints.
FTextFieldSizeStyles textFieldStyles({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required bool touch,
}) => FTextFieldSizeStyles.inherit(
  colors: colors,
  typography: typography,
  style: style,
  touch: touch,
);
