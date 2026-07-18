import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// Genesix color tokens, kept separate following the Forui CLI 0.24 layout.
final FColors genesixLightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  barrier: Color(0x33000000),
  background: Color(0xFFFFFFFF),
  foreground: Color(0xFF030712),
  primary: Color(0xFF1AE3C2),
  primaryForeground: Color(0xFFF9FAFB),
  secondary: Color(0xFFF3F4F6),
  secondaryForeground: Color(0xFF111827),
  muted: Color(0xFFF3F4F6),
  mutedForeground: Color(0xFF6B7280),
  destructive: Color(0xFFEF4444),
  destructiveForeground: Color(0xFFF9FAFB),
  error: Color(0xFFEF4444),
  errorForeground: Color(0xFFF9FAFB),
  border: Color(0xFFE5E7EB),
  card: Color(0xFFFFFFFF),
);

final FColors genesixDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  barrier: Color(0x7A000000),
  background: Color(0xFF030712),
  foreground: Color(0xFFF9FAFB),
  primary: Color(0xFF15BFAE),
  primaryForeground: Color(0xFFF9FAFB),
  secondary: Color(0xFF1F2937),
  secondaryForeground: Color(0xFFF9FAFB),
  muted: Color(0xFF1F2937),
  mutedForeground: Color(0xFF9CA3AF),
  destructive: Color(0xFF7F1D1D),
  destructiveForeground: Color(0xFFF9FAFB),
  error: Color(0xFF7F1D1D),
  errorForeground: Color(0xFFF9FAFB),
  border: Color(0xFF1F2937),
  card: Color(0xFF030712),
);
