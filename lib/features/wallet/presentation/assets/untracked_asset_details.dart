import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/xelis_wallet_asset_metadata_extensions.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class UntrackedAssetDetails extends ConsumerStatefulWidget {
  const UntrackedAssetDetails(
    this.hash,
    this.asset, {
    super.key,
    this.isTracking = false,
    this.onTrack,
  });

  final String hash;
  final XelisWalletAssetMetadata asset;
  final bool isTracking;
  final VoidCallback? onTrack;

  @override
  ConsumerState createState() => _UntrackedAssetDetailsState();
}

class _UntrackedAssetDetailsState extends ConsumerState<UntrackedAssetDetails> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final maxSupply = widget.asset.maxSupply.amountOrNull;
    final originContract = widget.asset.owner.originContractOrNull;

    return AppDialog(
      clipBehavior: Clip.antiAlias,
      title: Text(loc.details.capitalize()),
      body: FadedScroll(
        controller: _controller,
        child: SingleChildScrollView(
          controller: _controller,
          child: Padding(
            padding: const EdgeInsets.only(top: Spaces.medium),
            child: Column(
              spacing: Spaces.medium,
              children: [
                Text(
                  loc.track_asset_dialog_message,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                FDivider(),
                LabeledValue.child(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.name.capitalize(),
                  AssetNameWidget(
                    assetName: widget.asset.name,
                    isXelis: isXelis(widget.hash),
                  ),
                ),
                LabeledValue.text(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.ticker,
                  widget.asset.ticker,
                ),
                LabeledValue.child(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.hash.capitalize(),
                  FTappable(
                    semanticsTooltip: loc.copy,
                    onPress: () =>
                        copyToClipboard(widget.hash, ref, loc.copied),
                    builder: (context, states, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            states.contains(FTappableVariant.hovered) ||
                                states.contains(FTappableVariant.pressed)
                            ? context.theme.colors.secondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: child,
                    ),
                    child: Text(
                      widget.hash,
                      style: context.theme.typography.body.md,
                    ),
                  ),
                ),
                LabeledValue.text(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.decimals,
                  widget.asset.decimals.toString(),
                ),
                if (maxSupply != null)
                  LabeledValue.child(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.max_supply,
                    Text(
                      formatCoin(
                        maxSupply,
                        widget.asset.decimals,
                        widget.asset.ticker,
                      ),
                      style: context.theme.typography.body.md,
                    ),
                  ),
                if (originContract != null)
                  LabeledValue.text(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    "Origin",
                    originContract,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FButton(
          onPress: widget.isTracking
              ? null
              : () {
                  widget.onTrack?.call();
                  context.pop();
                },
          child: widget.isTracking
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: Spaces.small),
                    Text('Tracking...'),
                  ],
                )
              : Text('Tracking'),
        ),
      ],
    );
  }
}
