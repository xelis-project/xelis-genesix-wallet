import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class NetworkTopWidget extends ConsumerWidget {
  const NetworkTopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network =
        ref.watch(settingsProvider.select((state) => state.network));
    final displayTopBar = network != Network.mainnet;

    if (displayTopBar) {
      return Container(
        decoration: BoxDecoration(color: context.colors.background),
        padding: const EdgeInsets.all(Spaces.small),
        child: Text(
          "Network: ${translateNetworkName(network)}",
          style: context.bodyMedium,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
