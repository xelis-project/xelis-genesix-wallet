import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

/*class BackHeader extends StatelessWidget {
  final String title;

  const BackHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flex(
          direction: Axis.horizontal,
          children: [
            IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                size: 30,
              ),
            ),
            const SizedBox(width: Spaces.small),
            Text(
              title,
              style:
                  context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(
          height: Spaces.medium,
        ),
      ],
    );
  }
}*/

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
    /*return Container(
      padding: const EdgeInsets.fromLTRB(
          Spaces.none, Spaces.medium, Spaces.none, Spaces.medium),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: context.titleLarge),
          SelectableText(value,
              style: context.bodyLarge!.copyWith(color: context.colors.primary))
        ],
      ),
    );*/
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
/*    return Container(
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
    );*/
  }
}
