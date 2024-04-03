import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

const List<Network> networks = <Network>[
  Network.mainnet,
  Network.testnet,
  Network.dev,
];

class NetworkSelectorWidget extends ConsumerWidget {
  const NetworkSelectorWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authentication = ref.watch(authenticationProvider);
    final loc = ref.watch(appLocalizationsProvider);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: Border.all(color: Colors.transparent, width: 0),
      collapsedShape: Border.all(color: Colors.transparent, width: 0),
      title: Text(
        loc.network,
        style: context.titleLarge,
      ),
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
                      .read(snackbarContentProvider.notifier)
                      .setContent(const SnackbarEvent.info(
                        message: 'Can\'t set network if the wallet is opened.',
                      ));
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
