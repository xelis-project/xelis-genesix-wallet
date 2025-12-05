import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

class NetworkSelectMenuTile extends ConsumerWidget {
  const NetworkSelectMenuTile({super.key, this.onSelected});

  final ValueChanged<Network>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final loc = ref.watch(appLocalizationsProvider);

    return FSelectMenuTile(
      title: Text(loc.network),
      initialValue: network,
      detailsBuilder: (_, values, _) =>
          Text(translateNetworkName(loc, values.first)),
      menu: [
        FSelectTile(title: Text(loc.mainnet), value: Network.mainnet),
        FSelectTile(title: Text(loc.testnet), value: Network.testnet),
        FSelectTile(title: Text(loc.stagenet), value: Network.stagenet),
        FSelectTile(title: Text(loc.devnet), value: Network.devnet),
      ],
      onSelect: (value) {
        final selectedNetwork = value.$1;
        ref.read(settingsProvider.notifier).setNetwork(selectedNetwork);
        onSelected?.call(selectedNetwork);
      },
    );
  }
}
