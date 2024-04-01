import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NetworkTopWidget extends ConsumerWidget {
  const NetworkTopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final displayTopBar = settings.network != Network.mainnet;

    if (displayTopBar) {
      return Container(
        decoration: BoxDecoration(color: context.colors.background),
        padding: const EdgeInsets.all(Spaces.small),
        child: Text(
          "Network: ${translateNetworkName(settings.network)}",
          style: context.bodyLarge,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
