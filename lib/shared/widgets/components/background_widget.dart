import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

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
          child: child,
        ),
      ),
    );
  }
}
