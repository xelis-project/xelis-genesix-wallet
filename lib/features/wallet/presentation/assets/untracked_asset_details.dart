import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class UntrackedAssetDetails extends ConsumerStatefulWidget {
  const UntrackedAssetDetails(this.hash, this.asset, {super.key});

  final String hash;
  final sdk.AssetData asset;

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

    return FDialog(
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
                  style: context.theme.typography.sm.copyWith(
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
                  InkWell(
                    child: Text(
                      widget.hash,
                      style: context.theme.typography.base,
                    ),
                    onTap: () => copyToClipboard(widget.hash, ref, loc.copied),
                  ),
                ),
                LabeledValue.text(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.decimals,
                  widget.asset.decimals.toString(),
                ),
                if (widget.asset.maxSupply.getMax() != null)
                  LabeledValue.child(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.max_supply,
                    Text(
                      formatCoin(
                        widget.asset.maxSupply.getMax()!,
                        widget.asset.decimals,
                        widget.asset.ticker,
                      ),
                      style: context.theme.typography.base,
                    ),
                  ),
                if (!widget.asset.owner.isNone)
                  LabeledValue.text(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    "Origin",
                    widget.asset.owner.originContract!,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FButton(
          onPress: () {
            ref.read(walletStateProvider.notifier).trackAsset(widget.hash);
            context.pop();
          },
          child: Text(loc.track),
        ),
      ],
    );
  }
}
