import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';

class LastNewsCard extends ConsumerWidget {
  const LastNewsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last News',
                  style: context.theme.typography.xl.copyWith(
                    color: context.theme.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spaces.small),
          Text(
            'No news available at the moment.',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
