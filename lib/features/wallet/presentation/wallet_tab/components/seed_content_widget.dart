import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/theme/extensions.dart';

import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

class SeedContentWidget extends ConsumerWidget {
  const SeedContentWidget(this.seed, {super.key});

  final String? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: context.colors.primary),
              borderRadius: BorderRadius.circular(8.0)),
          child: Row(
            children: [
              Expanded(
                child: Icon(
                  Icons.warning_amber,
                  color: context.colors.primary,
                  size: 40,
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.small),
                  child: RichText(
                    text: TextSpan(
                        style: context.bodyMedium
                            ?.copyWith(color: context.colors.primary),
                        children: [
                          TextSpan(
                            text:
                                '${loc.seed_warning_message_1}\n${loc.seed_warning_message_2}\n\n',
                          ),
                          TextSpan(
                              text: '${loc.seed_warning}\n',
                              style: context.bodyMedium?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: loc.seed_warning_message_3,
                          ),
                        ]),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.seed_warning_message_4,
          style: context.titleMedium,
        ),
        Card.outlined(
          margin: const EdgeInsets.all(Spaces.none),
          child: Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: SelectableText(
              seed ?? loc.oups,
              style: context.bodyLarge,
            ),
          ),
        )
      ],
    );
  }
}
