import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';

FTile offlineModeToggleTile(WidgetRef ref, {bool enabled = true}) {
  final loc = ref.watch(appLocalizationsProvider);
  final offlineMode = ref.watch(
    settingsProvider.select((state) => state.walletOfflineMode),
  );

  return FTile(
    prefix: Icon(FLucideIcons.waypoints),
    title: Text(loc.offline_mode),
    subtitle: Text(loc.offline_mode_description),
    suffix: FSwitch(
      value: offlineMode,
      onChange: enabled
          ? (value) {
              ref.read(settingsProvider.notifier).setWalletOfflineMode(value);
            }
          : null,
    ),
  );
}

class OfflineModeToggleTile extends ConsumerWidget {
  const OfflineModeToggleTile({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return offlineModeToggleTile(ref, enabled: enabled);
  }
}
