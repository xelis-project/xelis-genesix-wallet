import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';

class GridInfoWidget extends StatefulWidget {
  const GridInfoWidget({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final Widget label;
  final Widget value;

  /// When set to `true`, briefly flashes the card background.
  final bool highlight;

  @override
  State<GridInfoWidget> createState() => _GridInfoWidgetState();
}

class _GridInfoWidgetState extends State<GridInfoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _highlightController;
  late final Animation<double> _highlightOpacity;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: AppDurations.animSlow),
      vsync: this,
    );
    _highlightOpacity = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(GridInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !oldWidget.highlight) {
      _highlightController.forward(from: 0).then((_) {
        if (mounted) _highlightController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
      child: AnimatedBuilder(
        animation: _highlightOpacity,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: context.theme.colors.primary.withValues(
                alpha: 0.08 * _highlightOpacity.value,
              ),
              borderRadius: context.theme.style.borderRadius.md,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [widget.label, widget.value],
          ),
        ),
      ),
    );
  }
}
