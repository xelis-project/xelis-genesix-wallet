import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
            elevation: 10,
            contentPadding: const EdgeInsets.all(Spaces.medium),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                              Icons.info_outline,
                              color: context.colors.primary,
                              size: 30,
                            ),
                            const SizedBox(width: Spaces.medium),
                            Text(
                              loc.wait,
                              style: context.bodyLarge?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spaces.small),
                        Text(
                          loc.table_generation_message,
                          style: context.bodyMedium
                              ?.copyWith(color: context.colors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spaces.medium),
                Text(
                  step,
                  style:
                      context.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Spaces.small),
                LinearProgressIndicator(
                  value: progressValue,
                  semanticsLabel: (progressValue * 100).toStringAsPrecision(3),
                  borderRadius: BorderRadius.circular(8.0),
                  minHeight: 10,
                ),
                const SizedBox(height: Spaces.small),
                Text('${(progressValue * 100).toStringAsPrecision(3)}%',
                    style: context.headlineMedium),
              ],
            ),
          );
        });
  }
}
