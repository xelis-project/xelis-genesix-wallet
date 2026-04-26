import 'package:flutter/material.dart';

class GenericDialog extends StatelessWidget {
  const GenericDialog({
    this.title,
    this.content,
    this.actions,
    this.scrollable = true,
    super.key,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
    );
  }
}
