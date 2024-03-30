import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/network_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_state.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NetworkTopWidget extends ConsumerWidget {
  const NetworkTopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final displayTopBar = network.networkType != NetworkType.mainnet;

    if (displayTopBar) {
      return Container(
        decoration: const BoxDecoration(color: Colors.black),
        padding: const EdgeInsets.all(Spaces.small),
        child: Text(
          "Network: ${translateNetworkName(network.networkType)}",
          style: context.bodyLarge,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
