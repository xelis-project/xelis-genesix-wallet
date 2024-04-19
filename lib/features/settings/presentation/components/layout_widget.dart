import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class HorizontalContainer extends StatelessWidget {
  final String title;
  final String value;

  const HorizontalContainer(
      {super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: context.titleLarge),
          SelectableText(value,
              style: context.bodyLarge!.copyWith(color: context.colors.primary))
        ],
      ),
    );
  }
}

class VerticalContainer extends StatelessWidget {
  final String title;
  final String value;

  const VerticalContainer(
      {super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.titleLarge),
          const SizedBox(height: Spaces.small),
          SelectableText(value,
              style: context.bodyLarge!.copyWith(color: context.colors.primary))
        ],
      ),
    );
  }
}
