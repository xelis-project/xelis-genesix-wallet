import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/theme/extensions.dart';

import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

class SeedContentDialog extends ConsumerWidget {
  const SeedContentDialog(this.seed, WidgetRef ref, {super.key});

  final String? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return AlertDialog(
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.seed_warning_message_4,
            style: context.titleLarge,
          ),
          const SizedBox(
            height: Spaces.medium,
          ),
          SelectableText(
            seed ?? loc.oups,
            style: context.bodyLarge!
                .copyWith(color: context.moreColors.mutedColor),
          ),
          const SizedBox(
            height: Spaces.medium,
          ),
          Text(
            'Save it somewhere safe. You can write it down on a piece of paper.',
            style: context.titleMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Yes, I have saved my seed."),
        )
      ],
    );
  }
}
