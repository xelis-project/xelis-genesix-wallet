import 'package:flutter/widgets.dart';

/// Vertically interpolates setup states without retaining the outgoing
/// widget's full height until the end of the transition.
class MultisigSetupAnimatedSwitcher extends StatelessWidget {
  const MultisigSetupAnimatedSwitcher({
    required this.duration,
    required this.child,
    super.key,
  });

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, animation) =>
            _MultisigSetupStateTransition(animation: animation, child: child),
        layoutBuilder: (currentChild, previousChildren) =>
            _MultisigSetupSwitcherLayout(
              currentChild: currentChild,
              previousChildren: previousChildren,
            ),
        child: child,
      ),
    );
  }
}

class _MultisigSetupSwitcherLayout extends StatelessWidget {
  const _MultisigSetupSwitcherLayout({
    required this.currentChild,
    required this.previousChildren,
  });

  final Widget? currentChild;
  final List<Widget> previousChildren;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...previousChildren, ?currentChild],
    );
  }
}

class _MultisigSetupStateTransition extends StatelessWidget {
  const _MultisigSetupStateTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        alignment: AlignmentDirectional.topStart,
        child: child,
      ),
    );
  }
}
