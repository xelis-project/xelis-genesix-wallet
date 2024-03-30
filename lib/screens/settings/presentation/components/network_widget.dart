import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/network_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_state.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/network_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

const List<NetworkType> networkTypes = <NetworkType>[
  NetworkType.mainnet,
  NetworkType.testnet,
  NetworkType.dev,
];

class NetworkWidget extends ConsumerWidget {
  const NetworkWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNetwork = ref.watch(networkProvider);
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
        translateNetworkName(currentNetwork.networkType),
        style: context.titleMedium!.copyWith(color: context.colors.primary),
      ),
      children: List<ListTile>.generate(
        networkTypes.length,
        (index) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            translateNetworkName(networkTypes[index]),
            style: context.titleMedium,
          ),
          leading: Radio<NetworkType>(
            value: networkTypes[index],
            groupValue: currentNetwork.networkType,
            onChanged: (value) {
              if (value != null) {
                ref.read(networkProvider.notifier).setNetwork(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
