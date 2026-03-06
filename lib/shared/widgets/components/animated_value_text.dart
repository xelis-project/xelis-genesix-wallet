import 'package:flutter/widgets.dart';
import 'package:genesix/shared/theme/constants.dart';

class AnimatedValueText extends StatefulWidget {
  const AnimatedValueText({
    super.key,
    required this.value,
    required this.style,
    this.textAlign,
    this.onChanged,
  });

  final String value;
  final TextStyle style;
  final TextAlign? textAlign;

  /// Called when the displayed value changes (not on the initial build).
  final VoidCallback? onChanged;

  @override
  State<AnimatedValueText> createState() => _AnimatedValueTextState();
}

class _AnimatedValueTextState extends State<AnimatedValueText> {
  String? _previousValue;

  @override
  void didUpdateWidget(AnimatedValueText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _previousValue != null) {
      // Defer to avoid setState-during-build when ancestors listen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged?.call();
      });
    }
    _previousValue = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: AppDurations.animNormal),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        key: ValueKey<String>(widget.value),
        widget.value,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
