import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class GridInfoWidget extends StatefulWidget {
  const GridInfoWidget({
    super.key,
    required this.label,
    this.value,
    this.isLoading = false,
  });

  final String label;
  final String? value;
  final bool isLoading;

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
    if (oldWidget.value != null &&
        widget.value != null &&
        widget.value != oldWidget.value) {
      _runHighlight();
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  void _runHighlight() {
    _highlightController.forward(from: 0).then((_) {
      if (mounted) _highlightController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.theme.typography.body.sm.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    final valueStyle = context.theme.typography.body.md;

    return FCard(
      clipBehavior: Clip.antiAlias,
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
            children: [
              Text(
                widget.label,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
              _GridInfoValueText(
                value: widget.value,
                style: valueStyle,
                isLoading: widget.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridInfoValueText extends StatelessWidget {
  const _GridInfoValueText({
    required this.value,
    required this.style,
    required this.isLoading,
  });

  final String? value;
  final TextStyle style;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Bone.text(width: 96, style: style, textAlign: TextAlign.center);
    }

    final value = this.value ?? '-';
    return Text(
      value,
      style: style.copyWith(
        fontFeatures: [
          ...?style.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
