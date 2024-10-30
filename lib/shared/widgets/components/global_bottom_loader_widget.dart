import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

class GlobalBottomLoader extends StatelessWidget {
  final Widget child;

  const GlobalBottomLoader({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLoaderOverlay(
      overlayColor: Colors.black45,
      overlayWidgetBuilder: (_) {
        return const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 50),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Colors.white,
                strokeCap: StrokeCap.round,
                strokeWidth: 6,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
