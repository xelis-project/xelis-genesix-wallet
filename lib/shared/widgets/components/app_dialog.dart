import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A Genesix-owned dialog layout built on Forui's unopinionated [FDialog].
///
/// The public shape intentionally mirrors the pre-0.24 Forui dialog API so
/// feature dialogs keep their semantics while Genesix owns their layout.
class AppDialog extends StatelessWidget {
  const AppDialog({
    this.image,
    this.title,
    this.body,
    this.actions = const [],
    this.direction = Axis.vertical,
    this.style = const .context(),
    this.clipBehavior = Clip.none,
    this.animation,
    this.semanticsLabel,
    this.constraints = const BoxConstraints(minWidth: 280, maxWidth: 560),
    this.resizeToAvoidInsets = true,
    super.key,
  }) : adaptive = false;

  const AppDialog.adaptive({
    this.image,
    this.title,
    this.body,
    this.actions = const [],
    this.style = const .context(),
    this.clipBehavior = Clip.none,
    this.animation,
    this.semanticsLabel,
    this.constraints = const BoxConstraints(minWidth: 280, maxWidth: 560),
    this.resizeToAvoidInsets = true,
    super.key,
  }) : adaptive = true,
       direction = Axis.vertical;

  final Widget? image;
  final Widget? title;
  final Widget? body;
  final List<Widget> actions;
  final Axis direction;
  final FDialogStyleDelta style;
  final Clip clipBehavior;
  final Animation<double>? animation;
  final String? semanticsLabel;
  final BoxConstraints constraints;
  final bool resizeToAvoidInsets;
  final bool adaptive;

  @override
  Widget build(BuildContext context) {
    if (adaptive) {
      return FDialog.adaptive(
        style: style,
        clipBehavior: clipBehavior,
        animation: animation,
        semanticsLabel: semanticsLabel,
        constraints: constraints,
        resizeToAvoidInsets: resizeToAvoidInsets,
        horizontalBuilder: _buildHorizontal,
        verticalBuilder: _buildVertical,
      );
    }

    return FDialog(
      style: style,
      clipBehavior: clipBehavior,
      animation: animation,
      semanticsLabel: semanticsLabel,
      constraints: constraints,
      resizeToAvoidInsets: resizeToAvoidInsets,
      builder: direction == Axis.horizontal ? _buildHorizontal : _buildVertical,
    );
  }

  Widget _buildHorizontal(BuildContext context, FDialogStyle style) =>
      _AppDialogContent(
        style: style,
        direction: Axis.horizontal,
        image: image,
        title: title,
        body: body,
        actions: actions,
      );

  Widget _buildVertical(BuildContext context, FDialogStyle style) =>
      _AppDialogContent(
        style: style,
        direction: Axis.vertical,
        image: image,
        title: title,
        body: body,
        actions: actions,
      );
}

class _AppDialogContent extends StatelessWidget {
  const _AppDialogContent({
    required this.style,
    required this.direction,
    required this.image,
    required this.title,
    required this.body,
    required this.actions,
  });

  final FDialogStyle style;
  final Axis direction;
  final Widget? image;
  final Widget? title;
  final Widget? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final touch = context.platformVariant.touch;
    final vertical = direction == Axis.vertical;
    final titleSpacing = touch ? 9.0 : 5.0;
    final contentSpacing = touch ? 20.0 : 16.0;
    final actionSpacing = touch ? 10.0 : 8.0;

    return Padding(
      padding: touch
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 18)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image case final image?) ...[
            image,
            if (title != null || body != null) SizedBox(height: contentSpacing),
          ],
          if (title case final title?) ...[
            Padding(
              padding: EdgeInsets.only(
                left: vertical || touch ? 8 : 0,
                right: vertical || touch ? 8 : 0,
              ),
              child: DefaultTextStyle.merge(
                style: style.titleTextStyle,
                child: title,
              ),
            ),
            if (body != null) SizedBox(height: titleSpacing),
          ],
          if (body case final body?)
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: vertical || touch ? 8 : 0,
                ),
                child: DefaultTextStyle.merge(
                  style: style.bodyTextStyle,
                  child: body,
                ),
              ),
            ),
          if (actions.isNotEmpty) ...[
            if (title != null || body != null || image != null)
              SizedBox(height: contentSpacing),
            if (vertical)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: actionSpacing,
                children: actions,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                spacing: actionSpacing,
                children: touch
                    ? [for (final action in actions) Expanded(child: action)]
                    : actions,
              ),
          ],
        ],
      ),
    );
  }
}
