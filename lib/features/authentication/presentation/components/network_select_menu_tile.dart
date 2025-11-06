import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
    print('NetworkSelectMenuTile build with network: $network');

    return FSelectMenuTile(
      title: const Text('Network'),
      initialValue: network,
      detailsBuilder: (_, values, _) =>
          Text(translateNetworkName(values.first)),
      menu: const [
        FSelectTile(title: Text('Mainnet'), value: Network.mainnet),
        FSelectTile(title: Text('Testnet'), value: Network.testnet),
        FSelectTile(title: Text('Stagenet'), value: Network.stagenet),
        FSelectTile(title: Text('Devnet'), value: Network.devnet),
      ],
      onSelect: (value) {
        final selectedNetwork = value.$1;
        ref.read(settingsProvider.notifier).setNetwork(selectedNetwork);
        onSelected?.call(selectedNetwork);
      },
    );
  }
}
