import 'package:flutter/material.dart';

/// A scrollable widget that fades content at the top and bottom edges
class FadedScroll extends StatelessWidget {
  const FadedScroll({
    super.key,
    required this.child,
    this.fadeExtent = 40.0,
    this.controller,
    this.scrollDirection = Axis.vertical,
  });

  final Widget child;
  final double fadeExtent;
  final ScrollController? controller;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: scrollDirection == Axis.vertical
              ? Alignment.topCenter
              : Alignment.centerLeft,
          end: scrollDirection == Axis.vertical
              ? Alignment.bottomCenter
              : Alignment.centerRight,
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [
            0.0,
            fadeExtent / (scrollDirection == Axis.vertical ? bounds.height : bounds.width),
            1.0 - fadeExtent / (scrollDirection == Axis.vertical ? bounds.height : bounds.width),
            1.0,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
