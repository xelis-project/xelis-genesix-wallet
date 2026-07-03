import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/network/grid_info_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/custom_skeletonizer.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class DaemonInfoWidget extends ConsumerStatefulWidget {
  const DaemonInfoWidget(this.info, {super.key, required this.isLoading});

  final DaemonInfoSnapshot? info;
  final bool isLoading;

  @override
  ConsumerState createState() => _DaemonInfoWidgetState();
}

class _DaemonInfoWidgetState extends ConsumerState<DaemonInfoWidget> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final info = widget.info;
    final isLoading = widget.isLoading;
    final isOffline = ref.watch(
      walletRuntimeProvider.select(
        (state) => state.connectionPhase == WalletConnectionPhase.offline,
      ),
    );

    if (isOffline && !isLoading) {
      return _OfflineDaemonInfoMessage(loc: loc);
    }

    final items = _buildItems(loc, info, isLoading);

    Widget grid = FadedScroll(
      controller: _controller,
      fadeFraction: 0.08,
      child: GridView.builder(
        controller: _controller,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.7,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      ),
    );

    if (isLoading) {
      return CustomSkeletonizer(child: grid);
    }

    return grid;
  }

  List<Widget> _buildItems(
    AppLocalizations loc,
    DaemonInfoSnapshot? info,
    bool isLoading,
  ) {
    return [
      GridInfoWidget(
        key: const ValueKey('height'),
        label: 'Height',
        value: info?.height,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('topoHeight'),
        label: loc.topoheight,
        value: info?.topoHeight,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('mempool'),
        label: loc.mempool,
        value: info?.mempoolSize.toString(),
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('circulatingSupply'),
        label: loc.circulating_supply,
        value: info?.circulatingSupply,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('emittedSupply'),
        label: 'Emitted Supply',
        value: info?.emittedSupply,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('burnSupply'),
        label: 'Burned Supply',
        value: info?.burnSupply,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('hashRate'),
        label: 'Hashrate',
        value: info?.hashRate,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('blockReward'),
        label: loc.block_reward,
        value: info?.blockReward,
        isLoading: isLoading,
      ),
      GridInfoWidget(
        key: const ValueKey('avgBlockTime'),
        label: loc.average_block_time,
        value: info != null
            ? '${info.averageBlockTime.inSeconds} ${loc.seconds}'
            : null,
        isLoading: isLoading,
      ),
    ];
  }
}

class _OfflineDaemonInfoMessage extends StatelessWidget {
  const _OfflineDaemonInfoMessage({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FLucideIcons.waypoints,
              size: 42,
              color: context.theme.colors.mutedForeground,
            ),
            const SizedBox(height: Spaces.medium),
            Text(
              loc.offline,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Text(
              loc.daemon_info_unavailable_offline,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            Text(
              loc.daemon_info_online_settings_hint,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
