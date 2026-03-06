import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';
import 'package:genesix/features/wallet/presentation/network/grid_info_widget.dart';
import 'package:genesix/shared/widgets/components/animated_value_text.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/shared/widgets/components/custom_skeletonizer.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class DaemonInfoWidget extends ConsumerStatefulWidget {
  const DaemonInfoWidget(this.info, {super.key});

  final DaemonInfoSnapshot? info;

  @override
  ConsumerState createState() => _DaemonInfoWidgetState();
}

class _DaemonInfoWidgetState extends ConsumerState<DaemonInfoWidget> {
  final _controller = ScrollController();
  final Map<String, bool> _highlights = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerHighlight(String key) {
    setState(() => _highlights[key] = true);
    // Reset after a frame so the next change can trigger again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _highlights[key] = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final info = widget.info;
    final isLoading = info == null;

    final items = _buildItems(context, loc, info);

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
    BuildContext context,
    AppLocalizations loc,
    DaemonInfoSnapshot? info,
  ) {
    final labelStyle = context.theme.typography.sm.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    final valueStyle = context.theme.typography.base;

    return [
      _InfoCell(
        cellKey: 'height',
        label: 'Height',
        value: info?.height ?? '1,234,567',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'topoHeight',
        label: loc.topoheight,
        value: info?.topoHeight ?? '2,345,678',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'mempool',
        label: loc.mempool,
        value: info?.mempoolSize.toString() ?? '12',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'circulatingSupply',
        label: loc.circulating_supply,
        value: info?.circulatingSupply ?? '15,234.56 XEL',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'emittedSupply',
        label: 'Emitted Supply',
        value: info?.emittedSupply ?? '18,400.00 XEL',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'burnSupply',
        label: 'Burned Supply',
        value: info?.burnSupply ?? '320.50 XEL',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'hashRate',
        label: 'Hashrate',
        value: info?.hashRate ?? '1.23 GH/s',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'blockReward',
        label: loc.block_reward,
        value: info?.blockReward ?? '1.42 XEL',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
      _InfoCell(
        cellKey: 'avgBlockTime',
        label: loc.average_block_time,
        value: info != null
            ? '${info.averageBlockTime.inSeconds} ${loc.seconds}'
            : '15 ${loc.seconds}',
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        highlights: _highlights,
        onHighlight: _triggerHighlight,
      ),
    ];
  }
}

class _InfoCell extends StatelessWidget {
  _InfoCell({
    required this.cellKey,
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.highlights,
    required this.onHighlight,
  }) : super(key: ValueKey(cellKey));

  final String cellKey;
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final Map<String, bool> highlights;
  final void Function(String key) onHighlight;

  @override
  Widget build(BuildContext context) {
    return GridInfoWidget(
      highlight: highlights[cellKey] ?? false,
      label: Text(label, style: labelStyle, textAlign: TextAlign.center),
      value: AnimatedValueText(
        value: value,
        style: valueStyle,
        textAlign: TextAlign.center,
        onChanged: () => onHighlight(cellKey),
      ),
    );
  }
}
