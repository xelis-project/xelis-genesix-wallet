import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class SheetContent extends StatelessWidget {
  SheetContent({super.key, required this.child});

  final Widget child;

  final _controller = ScrollController();

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
            child: FadedScroll(
              controller: _controller,
              child: SingleChildScrollView(
                controller: _controller,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
