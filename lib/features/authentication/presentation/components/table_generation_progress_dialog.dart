import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/progress_report_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class TableGenerationProgressDialog extends ConsumerWidget {
  const TableGenerationProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final stream = ref.watch(tableGenerationProgressProvider);
    return StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final progressValue = snapshot.data?.progress ?? 0.0;
          final step = snapshot.data?.step ?? '';
          return AlertDialog(
            scrollable: true,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: context.colors.primary),
                      borderRadius: BorderRadius.circular(8.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: Spaces.medium, horizontal: Spaces.small),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.colors.primary,
                          size: 50,
                        ),
                        const SizedBox(height: Spaces.small),
                        Text(
                          loc.wait,
                          style: context.bodyLarge?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: Spaces.small),
                        Text(
                          loc.table_generation_message,
                          style: context.bodyLarge?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spaces.large),
                const SizedBox(height: Spaces.large),
                Row(
                  children: [
                    Text(
                      loc.current_step,
                      style: context.bodyLarge,
                    ),
                    Text(
                      step,
                      style: context.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: Spaces.medium),
                LinearProgressIndicator(
                  value: progressValue,
                  semanticsLabel: (progressValue * 100).toStringAsPrecision(3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ],
            ),
          );
        });
  }
}
