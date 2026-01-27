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
import 'package:genesix/shared/widgets/components/network_mismatch_widget.dart';
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

    bool mismatch = ref.watch(networkMismatchProvider);

    final topoheight = ref.watch(
      walletStateProvider.select((state) => state.topoheight),
    );

    final isRescanning = ref.watch(
      walletStateProvider.select((state) => state.isRescanning),
    );

    var displayedTopoheight = NumberFormat().format(topoheight);

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spaces.extraSmall,
                children: [
                  Text(nodeAddress.name, style: context.theme.typography.sm),
                  Text(
                    nodeAddress.url,
                    style: context.theme.typography.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              ConnectionIndicator(),
            ],
          ),
          FDivider(
            style: context.theme.dividerStyles.horizontalStyle
                .copyWith(
                  padding: EdgeInsets.symmetric(vertical: Spaces.medium),
                )
                .call,
          ),
          mismatch
              ? NetworkMismatchWidget()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    FButton(
                      style: FButtonStyle.outline(),
                      onPress: isRescanning
                          ? null
                          : () async {
                              await ref
                                  .read(walletStateProvider.notifier)
                                  .rescan();
                            },
                      prefix: isRescanning
                          ? const FCircularProgress.loader()
                          : Icon(FIcons.rotateCcw),
                      child: isRescanning ? Text(loc.wait) : Text(loc.rescan),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
