import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';

class LabeledValue extends StatelessWidget {
  const LabeledValue._({
    required this.title,
    this.child,
    this.text,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.selectable = true,
    this.maxLines,
    this.textAlign,
    this.style,
    super.key,
  });

  factory LabeledValue.text(
    String title,
    String text, {
    Key? key,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    bool selectable = true,
    int? maxLines,
    TextAlign? textAlign,
    TextStyle? style,
  }) => LabeledValue._(
    key: key,
    title: title,
    text: text,
    crossAxisAlignment: crossAxisAlignment,
    selectable: selectable,
    maxLines: maxLines,
    textAlign: textAlign,
    style: style,
  );

  factory LabeledValue.child(
    String title,
    Widget child, {
    Key? key,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    TextStyle? style,
  }) => LabeledValue._(
    key: key,
    title: title,
    crossAxisAlignment: crossAxisAlignment,
    style: style,
    child: child,
  );

  final String title;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget? child;
  final String? text;
  final bool selectable;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final contentStyle = style ?? context.theme.typography.base;

    final Widget content =
        child ??
        (selectable
            ? SelectableText(
                text!,
                style: contentStyle,
                textAlign: textAlign,
                maxLines: maxLines,
              )
            : Text(
                text!,
                style: contentStyle,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: maxLines == null
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ));

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      spacing: Spaces.extraSmall,
      children: [
        Text(
          title,
          style: context.theme.typography.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        content,
      ],
    );
  }
}
