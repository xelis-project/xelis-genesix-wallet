import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class BodyLayoutBuilder extends StatelessWidget {
  const BodyLayoutBuilder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        double contentWidth;
        if (width < context.theme.breakpoints.sm) {
          // < sm : mobile
          contentWidth = width * 0.95;
        } else if (width < context.theme.breakpoints.md) {
          // sm
          contentWidth = 600;
        } else if (width < context.theme.breakpoints.lg) {
          // md
          contentWidth = 768;
        } else if (width < context.theme.breakpoints.xl) {
          // lg
          contentWidth = 900;
        } else if (width < context.theme.breakpoints.xl2) {
          // xl
          contentWidth = 1100;
        } else {
          // 2xl et plus
          contentWidth = 1280;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
              maxHeight: height,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
