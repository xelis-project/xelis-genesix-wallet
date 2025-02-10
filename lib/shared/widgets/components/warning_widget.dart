import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class WarningWidget extends ConsumerWidget {
  const WarningWidget(this._messages, {super.key});

  final List<String> _messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.read(appLocalizationsProvider);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.primary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: context.colors.primary,
                  size: 30,
                ),
                const SizedBox(width: Spaces.medium),
                Expanded(
                  child: Text(
                    loc.warning,
                    style: context.titleLarge
                        ?.copyWith(color: context.colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spaces.small),
            RichText(
                text: TextSpan(
              children: _messages
                  .map((message) => TextSpan(
                        text: message,
                        style: context.bodyMedium,
                      ))
                  .toList(),
            )),
          ],
        ),
      ),
    );
  }
}
