import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';

const List<Network> networks = <Network>[
  Network.mainnet,
  Network.testnet,
  Network.dev,
];

class NetworkSelectorWidget extends ConsumerWidget {
  const NetworkSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authentication = ref.watch(authenticationProvider);
    final loc = ref.watch(appLocalizationsProvider);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: Border.all(color: Colors.transparent, width: 0),
      collapsedShape: Border.all(color: Colors.transparent, width: 0),
      title: Text(loc.network, style: context.titleLarge),
      subtitle: Text(
        translateNetworkName(settings.network),
        style: context.titleMedium!.copyWith(color: context.colors.primary),
      ),
      children: List<ListTile>.generate(
        networks.length,
        (index) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            translateNetworkName(networks[index]),
            style: context.titleMedium,
          ),
          leading: Radio<Network>(
            value: networks[index],
            groupValue: settings.network,
            onChanged: (value) {
              if (value != null) {
                if (!authentication.isAuth) {
                  ref.read(settingsProvider.notifier).setNetwork(value);
                } else {
                  ref
                      .read(snackBarQueueProvider.notifier)
                      .showError(loc.change_network_error);
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
