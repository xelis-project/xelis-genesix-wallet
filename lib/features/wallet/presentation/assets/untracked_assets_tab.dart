import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/untracked_asset_details.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class UntrackedAssetsTab extends ConsumerStatefulWidget {
  const UntrackedAssetsTab(this.maxHeight, {super.key});

  final double maxHeight;

  @override
  ConsumerState createState() => _UntrackedAssetsTabState();
}

class _UntrackedAssetsTabState extends ConsumerState<UntrackedAssetsTab> {
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

    final untrackedAssets = knownAssets.keys
        .where((hash) => !balances.containsKey(hash))
        .toList();

    if (untrackedAssets.isEmpty) {
      return SizedBox(
        height: widget.maxHeight - 100,
        child: Center(
          child: Text(
            loc.no_untracked_assets,
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
          count: untrackedAssets.length,
          itemBuilder: (context, index) {
            final hash = untrackedAssets[index];
            final asset = knownAssets[hash]!;
            return FItem(
              title: Text(asset.name),
              subtitle: Text(asset.ticker),
              suffix: Icon(FIcons.plus),
              onPress: () => _trackAsset(hash, asset),
            );
          },
        ),
      );
    }
  }

  void _trackAsset(String hash, sdk.AssetData assetData) {
    showFDialog<void>(
      context: context,
      builder: (context, style, animation) =>
          UntrackedAssetDetails(hash, assetData),
    );
  }
}
