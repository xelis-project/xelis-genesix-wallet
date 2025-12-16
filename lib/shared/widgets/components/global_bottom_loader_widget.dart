import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:loader_overlay/loader_overlay.dart';

class GlobalBottomLoader extends StatelessWidget {
  final Widget child;

  const GlobalBottomLoader({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLoaderOverlay(
      overlayColor: context.theme.colors.barrier,
      overlayWidgetBuilder: (_) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 100),
            child: Transform.scale(scale: 2, child: FCircularProgress()),
          ),
        );
      },
      child: child,
    );
  }
}
