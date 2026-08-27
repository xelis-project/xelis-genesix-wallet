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
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

class TrackedAssetDetails extends ConsumerStatefulWidget {
  const TrackedAssetDetails(this.hash, this.asset, this.balance, {super.key});

  final String hash;
  final XelisWalletAssetMetadata asset;
  final BigInt balance;

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
    final maxSupply = widget.asset.maxSupply.amountOrNull;
    final originContract = widget.asset.owner.originContractOrNull;
    final originId = widget.asset.owner.originIdOrNull;

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
                LabeledValue.child(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.name.capitalize(),
                  AssetNameWidget(
                    assetName: widget.asset.name,
                    isXelis: isXelis(widget.hash),
                  ),
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
                if (originContract != null && originId != null) ...[
                  LabeledValue.text(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.contract,
                    originContract,
                  ),
                  LabeledValue.text(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    loc.id,
                    originId.toString(),
                  ),
                ],
                LabeledValue.text(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  loc.balance.capitalize(),
                  formatCoin(
                    widget.balance,
                    widget.asset.decimals,
                    widget.asset.ticker,
                  ),
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
              ref.read(walletCommandsProvider).untrackAsset(widget.hash);
              context.pop();
            },
            child: Text(loc.untrack.capitalize()),
          ),
      ],
    );
  }
}
