import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class BurnWarningWidget extends ConsumerWidget {
  const BurnWarningWidget(this._message, {super.key});

  final String _message;

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
                    child: Text(loc.warning,
                        style: context.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary))),
              ],
            ),
            const SizedBox(height: Spaces.small),
            Text(
              _message,
              style: context.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
