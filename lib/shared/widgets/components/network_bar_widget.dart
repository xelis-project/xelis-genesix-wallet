import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/network.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class NetworkTopWidget extends ConsumerWidget {
  const NetworkTopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final displayTopBar = network != Network.mainnet;

    if (displayTopBar) {
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(color: context.colors.shadow, blurRadius: Spaces.small),
          ],
        ),
        padding: const EdgeInsets.all(Spaces.small),
        child: Text(
          "${loc.network}: ${translateNetworkName(network)}",
          style: context.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
