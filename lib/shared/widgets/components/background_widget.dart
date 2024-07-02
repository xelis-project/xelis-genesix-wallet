import 'package:flutter/material.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/extensions.dart';

class Background extends StatelessWidget {
  final Widget child;
  const Background({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            context.moreColors.bgRadialColor1,
            context.moreColors.bgRadialEndColor,
          ],
          radius: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            colors: [
              context.moreColors.bgRadialColor2,
              context.moreColors.bgRadialEndColor,
            ],
            radius: 1.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.centerLeft,
              colors: [
                context.moreColors.bgRadialColor3,
                context.moreColors.bgRadialEndColor,
              ],
              radius: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                // https://github.com/flutter/flutter/issues/104114
                // opacity is not working for mobile browser so we applied it directly to the png image
                // opacity: .05,
                repeat: ImageRepeat.repeat,
                alignment: Alignment.topLeft,
                image: AppResources.bgDots.image,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
