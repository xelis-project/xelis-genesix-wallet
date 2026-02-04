import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/untracked_asset_details.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
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
  final Set<String> _trackingAssets = {};

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
            final isTracking = _trackingAssets.contains(hash);
            return FItem(
              title: Text(asset.name),
              subtitle: Text(asset.ticker),
              onPress: () => _showDetails(hash, asset),
              suffix: isTracking
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _trackAssetDirect(hash),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(FIcons.plus),
                      ),
                    ),
            );
          },
        ),
      );
    }
  }

  Future<void> _trackAssetDirect(String hash) async {
    setState(() => _trackingAssets.add(hash));
    await ref.read(walletStateProvider.notifier).trackAsset(hash);
    // Asset will be removed from untracked list automatically once tracked
    // but clean up the set just in case
    if (mounted) {
      setState(() => _trackingAssets.remove(hash));
    }
  }

  void _showDetails(String hash, sdk.AssetData assetData) {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => UntrackedAssetDetails(
        hash,
        assetData,
        isTracking: _trackingAssets.contains(hash),
        onTrack: () => _trackAssetDirect(hash),
      ),
    );
  }
}
