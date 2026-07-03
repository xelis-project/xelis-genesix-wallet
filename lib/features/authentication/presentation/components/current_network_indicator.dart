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
    return const Align(
      alignment: Alignment.center,
      child: _CurrentNetworkIndicatorPill(),
    );
  }
}

class AuthenticationStatusIndicators extends StatelessWidget {
  const AuthenticationStatusIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: [_CurrentNetworkIndicatorPill(), _OfflineModeIndicatorPill()],
    );
  }
}

class OfflineModeIndicator extends StatelessWidget {
  const OfflineModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: _OfflineModeIndicatorPill(),
    );
  }
}

class _CurrentNetworkIndicatorPill extends ConsumerWidget {
  const _CurrentNetworkIndicatorPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final colors = context.theme.colors;
    final networkName = translateNetworkName(loc, network);

    return _IndicatorPill(
      accentColor: colors.primary,
      icon: FLucideIcons.waypoints,
      label: '${loc.network}: ',
      value: networkName,
    );
  }
}

class _OfflineModeIndicatorPill extends ConsumerWidget {
  const _OfflineModeIndicatorPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final offlineMode = ref.watch(
      settingsProvider.select((state) => state.walletOfflineMode),
    );
    final colors = context.theme.colors;
    final accentColor = offlineMode ? colors.mutedForeground : colors.primary;

    return _IndicatorPill(
      accentColor: accentColor,
      icon: FLucideIcons.cable,
      value: offlineMode ? loc.offline_mode : loc.online_mode,
    );
  }
}

class _IndicatorPill extends StatelessWidget {
  const _IndicatorPill({
    required this.accentColor,
    required this.icon,
    required this.value,
    this.label,
  });

  final Color accentColor;
  final IconData icon;
  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
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
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(width: Spaces.extraSmall),
            if (label != null)
              Text(
                label!,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            Text(
              value,
              style: context.theme.typography.body.sm.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
