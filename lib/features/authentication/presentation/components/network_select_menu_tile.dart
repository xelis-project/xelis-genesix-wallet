import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

class NetworkSelectMenuTile extends ConsumerStatefulWidget {
  const NetworkSelectMenuTile({super.key, this.onSelected});

  final ValueChanged<Network>? onSelected;

  @override
  ConsumerState<NetworkSelectMenuTile> createState() =>
      _NetworkSelectMenuTileState();
}

class _NetworkSelectMenuTileState extends ConsumerState<NetworkSelectMenuTile> {
  late final FMultiValueNotifier<Network> _controller;

  @override
  void initState() {
    super.initState();
    final initialNetwork = ref.read(
      settingsProvider.select((state) => state.network),
    );

    _controller = FMultiValueNotifier<Network>.radio(initialNetwork);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );

    if (_controller.value.length != 1 || _controller.value.first != network) {
      _controller.value = {network};
    }

    return FSelectMenuTile(
      title: Text(loc.network),
      selectControl: .managedRadio(
        controller: _controller,
        onChange: (values) {
          final selected = values.isEmpty ? null : values.first;
          if (selected == null) return;

          ref.read(settingsProvider.notifier).setNetwork(selected);
          widget.onSelected?.call(selected);
        },
      ),
      detailsBuilder: (_, values, _) {
        final selected = values.isEmpty ? network : values.first;
        return Text(translateNetworkName(loc, selected));
      },
      menu: [
        FSelectTile(title: Text(loc.mainnet), value: Network.mainnet),
        FSelectTile(title: Text(loc.testnet), value: Network.testnet),
        FSelectTile(title: Text(loc.stagenet), value: Network.stagenet),
        FSelectTile(title: Text(loc.devnet), value: Network.devnet),
      ],
    );
  }
}
