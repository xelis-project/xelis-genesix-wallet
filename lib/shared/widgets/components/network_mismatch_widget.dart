import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

class NetworkMismatchWidget extends ConsumerWidget {
  const NetworkMismatchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(FIcons.triangleAlert, color: context.theme.colors.error, size: 24),
        const SizedBox(width: Spaces.small),
        Flexible(
          child: Text(
            loc.network_mismatch,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
