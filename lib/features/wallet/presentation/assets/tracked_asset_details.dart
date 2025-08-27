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

class TrackedAssetDetails extends ConsumerStatefulWidget {
  const TrackedAssetDetails(this.hash, this.asset, this.balance, {super.key});

  final String hash;
  final sdk.AssetData asset;
  final String balance;

  @override
  ConsumerState createState() => _TrackedAssetDetailsState();
}

class _TrackedAssetDetailsState extends ConsumerState<TrackedAssetDetails> {
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
                LabeledValue.child(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.name.capitalize(),
                  AssetNameWidget(
                    assetName: widget.hash,
                    isXelis: isXelis(widget.hash),
                  ),
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
                if (widget.asset.maxSupply != null)
                  LabeledValue.child(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.max_supply,
                    Text(
                      formatCoin(
                        widget.asset.maxSupply!,
                        widget.asset.decimals,
                        widget.asset.ticker,
                      ),
                      style: context.theme.typography.base,
                    ),
                  ),
                if (widget.asset.owner != null) ...[
                  LabeledValue.text(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.contract,
                    widget.asset.owner!.contract,
                  ),
                  LabeledValue.text(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.id,
                    widget.asset.owner!.id.toString(),
                  ),
                ],
                LabeledValue.text(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.balance.capitalize(),
                  '${widget.balance} ${widget.asset.ticker}',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!isXelis(widget.hash))
          FButton(
            onPress: () {
              ref.read(walletStateProvider.notifier).untrackAsset(widget.hash);
              context.pop();
            },
            child: Text(loc.untrack.capitalize()),
          ),
      ],
    );
  }
}
