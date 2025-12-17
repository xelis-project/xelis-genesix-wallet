import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';
import 'package:genesix/features/wallet/presentation/network/grid_info_widget.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class DaemonInfoWidget extends ConsumerStatefulWidget {
  const DaemonInfoWidget(this.info, {super.key});

  final DaemonInfoSnapshot? info;

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

    List<Widget> items = [
      GridInfoWidget(
        items: [
          Text(
            'Height',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.height ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            loc.topoheight,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.topoHeight ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            loc.mempool,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            key: ValueKey(widget.info?.mempoolSize),
            widget.info?.mempoolSize.toString() ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            loc.circulating_supply,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.circulatingSupply ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            'Emitted Supply',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.emittedSupply ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            'Burned Supply',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.burnSupply ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            'Hashrate',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.hashRate ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            loc.block_reward,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.info?.blockReward ?? '...',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      GridInfoWidget(
        items: [
          Text(
            loc.average_block_time,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${widget.info?.averageBlockTime.inSeconds.toString() ?? '...'} ${loc.seconds}',
            style: context.theme.typography.base,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ];

    return FadedScroll(
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
        itemBuilder: (context, index) {
          return items[index];
        },
      ),
    );
  }
}
