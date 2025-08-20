import 'dart:math';

import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

/// Fades the edges of a scrollable child and auto-hides fades
/// at start/end using only a ScrollController.
///
/// The child MUST use the SAME [controller].
class FadedScroll extends StatefulWidget {
  const FadedScroll({
    super.key,
    required this.child,
    required this.controller, // required: same controller as child's
    this.axis = Axis.vertical,
    this.fadeFraction = 0.06,
    this.fadeColor = Colors.black,
    this.blendMode = BlendMode.dstIn,
    this.height,
    this.width,
    this.epsilon = 0.0, // if 0.0, we'll compute from DPR
  }) : assert(fadeFraction >= 0 && fadeFraction <= 0.5);

  /// Scrollable child (ListView, SingleChildScrollView, etc.).
  /// Must use [controller].
  final Widget child;

  /// The SAME controller used by the child.
  final ScrollController controller;

  /// Fade direction (horizontal or vertical).
  final Axis axis;

  /// Fraction of the size used for the fade (0.0–0.5 recommended).
  final double fadeFraction;

  /// Mask color (black recommended with dstIn).
  final Color fadeColor;

  /// Blend mode for the mask (dstIn keeps child opacity).
  final BlendMode blendMode;

  /// Optional fixed wrapper size.
  final double? height;
  final double? width;

  /// Tolerance (logical px) to consider "close enough" to edges (avoids ghost fades).
  /// If 0.0, computed as ~2 physical px.
  final double epsilon;

  @override
  State<FadedScroll> createState() => _FadedScrollState();
}

class _FadedScrollState extends State<FadedScroll> {
  bool _showStart = false;
  bool _showEnd = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    // Ensure correct initial state after first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFromPosition());

    // Re-check after the frame fully settles (fixes initial 1.33px residues)
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _updateFromPosition();
    });
  }

  @override
  void didUpdateWidget(covariant FadedScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTick);
      widget.controller.addListener(_onTick);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateFromPosition(),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => _updateFromPosition();

  void _updateFromPosition() {
    if (!widget.controller.hasClients) return;
    final p = widget.controller.position;

    // Use max of user epsilon and ~2 physical pixels converted to logical px.
    final dpr = context.mediaQueryData.devicePixelRatio;
    final eps = max(widget.epsilon, 2.0 / dpr);
    final overflow = (p.maxScrollExtent - p.minScrollExtent) > eps;

    bool showStart = false;
    bool showEnd = false;

    if (overflow) {
      final atStart = p.pixels <= p.minScrollExtent + eps && !p.outOfRange;
      final atEnd = p.pixels >= p.maxScrollExtent - eps && !p.outOfRange;
      showStart = !atStart;
      showEnd = !atEnd;
    }

    if (showStart != _showStart || showEnd != _showEnd) {
      setState(() {
        _showStart = showStart;
        _showEnd = showEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = ShaderMask(
      // Inline closure ensures shaderCallback identity updates on rebuild.
      shaderCallback: (Rect bounds) {
        final s = _showStart ? widget.fadeFraction : 0.0;
        final e = _showEnd ? (1.0 - widget.fadeFraction) : 1.0;

        final colors = <Color>[
          _showStart ? Colors.transparent : widget.fadeColor,
          widget.fadeColor,
          widget.fadeColor,
          _showEnd ? Colors.transparent : widget.fadeColor,
        ];
        final stops = <double>[0.0, s, e, 1.0];

        final begin = widget.axis == Axis.horizontal
            ? Alignment.centerLeft
            : Alignment.topCenter;
        final end = widget.axis == Axis.horizontal
            ? Alignment.centerRight
            : Alignment.bottomCenter;

        return LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: stops,
        ).createShader(bounds);
      },
      blendMode: widget.blendMode,
      child: widget.child,
    );

    if (widget.height == null && widget.width == null) return masked;
    return SizedBox(height: widget.height, width: widget.width, child: masked);
  }
}
