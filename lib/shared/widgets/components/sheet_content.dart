import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';

class SheetContent extends StatelessWidget {
  const SheetContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.colors.background,
        border: Border.symmetric(
          horizontal: BorderSide(color: context.theme.colors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spaces.small,
          horizontal: Spaces.medium,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.theme.breakpoints.sm),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}
