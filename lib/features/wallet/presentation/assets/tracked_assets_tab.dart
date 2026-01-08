import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/features/wallet/presentation/assets/tracked_asset_details.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class TrackedAssetsTab extends ConsumerStatefulWidget {
  const TrackedAssetsTab(this.maxHeight, {super.key});

  final double maxHeight;

  @override
  ConsumerState createState() => _TrackedAssetsTabState();
}

class _TrackedAssetsTabState extends ConsumerState<TrackedAssetsTab> {
  final _controller = ScrollController();

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );

    // Filter out assets that don't have metadata yet (defensive)
    final validBalances = Map.fromEntries(
      balances.entries.where((entry) => knownAssets.containsKey(entry.key)),
    );

    if (validBalances.isEmpty) {
      return SizedBox(
        height: widget.maxHeight - 100,
        child: Center(
          child: Text(
            loc.no_tracked_assets,
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ),
      );
    } else {
      return FadedScroll(
        controller: _controller,
        fadeFraction: 0.08,
        child: FItemGroup.builder(
          maxHeight: widget.maxHeight - 100,
          scrollController: _controller,
          count: validBalances.length,
          itemBuilder: (context, index) {
            final hash = validBalances.keys.toList()[index];
            final asset = knownAssets[hash]!;
            final balance = validBalances[hash]!;
            return FItem(
              title: AssetNameWidget(
                assetName: asset.name,
                isXelis: isXelis(hash),
              ),
              details: Text('$balance ${asset.ticker}'),
              suffix: Icon(FIcons.chevronRight),
              onPress: () => _showDetails(hash, asset, balance),
            );
          },
        ),
      );
    }
  }

  void _showDetails(String hash, sdk.AssetData asset, String balance) {
    showFDialog<void>(
      context: context,
      builder: (context, style, animation) =>
          TrackedAssetDetails(hash, asset, balance),
    );
  }
}
