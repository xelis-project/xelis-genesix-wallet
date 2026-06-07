import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/shared/theme/constants.dart';

class CurrentNetworkIndicator extends ConsumerWidget {
  const CurrentNetworkIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final colors = context.theme.colors;
    final networkName = translateNetworkName(loc, network);

    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.06),
          border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spaces.medium,
            vertical: Spaces.extraSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FLucideIcons.waypoints, color: colors.primary, size: 16),
              const SizedBox(width: Spaces.extraSmall),
              Text(
                '${loc.network}: ',
                style: context.theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              Text(
                networkName,
                style: context.theme.typography.sm.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
