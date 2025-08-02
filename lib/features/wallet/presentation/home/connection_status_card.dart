import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_mismatch_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/connection_indicator.dart';
import 'package:intl/intl.dart';

class ConnectionStatusCard extends ConsumerWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final networkNodes = ref.watch(networkNodesProvider);
    NodeAddress nodeAddress = networkNodes.addressFor(network);

    // TODO handle mismatch properly
    bool mismatch = ref.watch(networkMismatchProvider);

    final topoheight = ref.watch(
      walletStateProvider.select((state) => state.topoheight),
    );

    var displayedTopoheight = NumberFormat().format(topoheight);

    ValueNotifier<bool> isRescanningNotifier = ValueNotifier(false);

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FItem(
            title: Text(nodeAddress.name),
            subtitle: Text(nodeAddress.url),
            details: ConnectionIndicator(),
          ),
          FDivider(
            style: context.theme.dividerStyles.horizontalStyle
                .copyWith(
                  padding: EdgeInsets.symmetric(vertical: Spaces.medium),
                )
                .call,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    loc.topoheight,
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  Text(
                    displayedTopoheight,
                    style: context.theme.typography.lg.copyWith(
                      color: context.theme.colors.primary,
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder(
                valueListenable: isRescanningNotifier,
                builder: (BuildContext context, bool isRescanning, Widget? _) {
                  return FButton(
                    style: FButtonStyle.outline(),
                    onPress: isRescanning
                        ? null
                        : () async {
                            isRescanningNotifier.value = true;
                            await ref
                                .read(walletStateProvider.notifier)
                                .rescan();
                            isRescanningNotifier.value = false;
                          },
                    prefix: Icon(FIcons.rotateCcw),
                    child: Text(loc.rescan),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
