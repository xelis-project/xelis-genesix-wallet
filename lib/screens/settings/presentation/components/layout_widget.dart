import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class HorizontalContainer extends StatelessWidget {
  final String title;
  final String value;

  const HorizontalContainer(
      {super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spaces.none, Spaces.medium, Spaces.none, Spaces.medium),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Version", style: context.titleLarge),
          SelectableText("0.1.0",
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spaces.none, Spaces.medium, Spaces.none, Spaces.medium),
      child: Flex(
        direction: Axis.vertical,
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
