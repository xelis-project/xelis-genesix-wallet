import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomSkeletonizer extends StatelessWidget {
  const CustomSkeletonizer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: context.theme.colors.muted,
        highlightColor: context.theme.colors.mutedForeground,
        duration: const Duration(seconds: 1),
      ),
      child: child,
    );
  }
}
