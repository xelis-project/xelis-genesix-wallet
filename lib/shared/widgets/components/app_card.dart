import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A Genesix-owned card layout built on Forui's unopinionated [FCard].
///
/// Forui 0.24 intentionally moved title, subtitle, image, and content layout
/// out of [FCard]. Keeping that layout here preserves consistent spacing while
/// allowing Genesix to evolve it independently from the package API.
class AppCard extends StatelessWidget {
  const AppCard({
    this.image,
    this.title,
    this.subtitle,
    this.child,
    this.mainAxisSize = MainAxisSize.min,
    this.style = const .context(),
    this.clipBehavior = Clip.none,
    super.key,
  });

  final Widget? image;
  final Widget? title;
  final Widget? subtitle;
  final Widget? child;
  final MainAxisSize mainAxisSize;
  final FCardStyleDelta style;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) => FCard(
    style: style,
    clipBehavior: clipBehavior,
    builder: (context, resolvedStyle, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: mainAxisSize,
      children: [
        ?image,
        Padding(
          padding: resolvedStyle.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: mainAxisSize,
            children: [
              if (title case final title?) ...[
                DefaultTextStyle.merge(
                  textHeightBehavior: _textHeightBehavior,
                  style: resolvedStyle.titleTextStyle,
                  child: title,
                ),
                if (subtitle != null || child != null)
                  const SizedBox(height: 2),
              ],
              if (subtitle case final subtitle?) ...[
                DefaultTextStyle.merge(
                  textHeightBehavior: _textHeightBehavior,
                  style: resolvedStyle.subtitleTextStyle,
                  child: subtitle,
                ),
                if (child != null) const SizedBox(height: 6),
              ],
              ?child,
            ],
          ),
        ),
      ],
    ),
  );
}

const _textHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
