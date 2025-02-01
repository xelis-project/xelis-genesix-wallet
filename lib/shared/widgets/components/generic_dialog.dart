import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:genesix/shared/theme/constants.dart';

class GenericDialog extends StatelessWidget {
  const GenericDialog(
      {super.key,
      this.scrollable = true,
      this.title,
      this.content,
      this.actions});

  final bool scrollable;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: AlertDialog(
        scrollable: scrollable,
        titlePadding: const EdgeInsets.fromLTRB(
            Spaces.none, Spaces.none, Spaces.none, Spaces.small),
        contentPadding: const EdgeInsets.fromLTRB(
            Spaces.medium, Spaces.medium, Spaces.medium, Spaces.large),
        actionsPadding: const EdgeInsets.fromLTRB(
            Spaces.medium, Spaces.none, Spaces.medium, Spaces.medium),
        title: title,
        content: AnimatedSize(
          alignment: Alignment.topCenter,
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: content,
        ),
        actions: actions,
      ),
    );
  }
}
