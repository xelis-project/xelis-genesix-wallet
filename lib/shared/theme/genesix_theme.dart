import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as material;

/// Applies Forui below the material_ui app and supports unmigrated dependencies.
class GenesixTheme extends StatelessWidget {
  const GenesixTheme({required this.data, required this.child, super.key});

  final FThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) => FTheme(
    data: data,
    // Required by skeletonizer/pagination/QR widgets using Flutter's old theme.
    // This official utility is intentionally deprecated for eventual removal.
    // ignore: deprecated_member_use
    child: material.MaterialUiCompatibilityBridge(child: child),
  );
}
