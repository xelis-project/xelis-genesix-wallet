import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

mixin TransactionBuilderMixin {
  Widget buildLabeledText(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spaces.extraSmall),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: context.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: context.moreColors.mutedColor,
          ),
          children: [TextSpan(text: value, style: context.bodyMedium)],
        ),
      ),
    );
  }
}
