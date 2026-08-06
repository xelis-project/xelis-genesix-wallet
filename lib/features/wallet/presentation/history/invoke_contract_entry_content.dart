import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/features/wallet/presentation/history/contract_asset_transfers.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

class InvokeContractEntryContent extends ConsumerStatefulWidget {
  const InvokeContractEntryContent(this.invokeContractEntry, {super.key});

  final wallet_flutter.XelisWalletInvokeContractEntry invokeContractEntry;

  @override
  ConsumerState<InvokeContractEntryContent> createState() =>
      _InvokeContractEntryContentState();
}

class _InvokeContractEntryContentState
    extends ConsumerState<InvokeContractEntryContent> {
  final Map<String, wallet_flutter.XelisWalletAssetMetadata> _fetchedAssets =
      {};

  @override
  void initState() {
    super.initState();
    _loadMissingAssetMetadata();
  }

  Future<void> _loadMissingAssetMetadata() async {
    final walletState = ref.read(walletRuntimeProvider);
    final knownAssets = walletState.knownAssets;
    final repository = ref.read(activeWalletRepositoryProvider);

    if (repository == null) return;

    final transactionAssetHashes = {
      ...widget.invokeContractEntry.deposits.map((deposit) => deposit.asset),
      ...widget.invokeContractEntry.received.expand(
        (group) => group.transfers.map((transfer) => transfer.asset),
      ),
    };

    for (final assetHash in transactionAssetHashes) {
      if (knownAssets.containsKey(assetHash)) continue;

      try {
        final assetData = await repository.getAssetMetadata(assetHash);
        if (!mounted ||
            !identical(ref.read(activeWalletRepositoryProvider), repository)) {
          return;
        }
        setState(() => _fetchedAssets[assetHash] = assetData);
      } catch (_) {
        // Metadata fetch is best-effort; unknown assets keep the fallback label.
        if (!mounted ||
            !identical(ref.read(activeWalletRepositoryProvider), repository)) {
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );

    // Merge known assets with fetched assets
    final allAssets = {...knownAssets, ..._fetchedAssets};

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            LabeledValue.child(
              loc.contract,
              Row(
                children: [
                  Expanded(
                    child: FTooltip(
                      tipBuilder: (context, controller) =>
                          SelectableText(widget.invokeContractEntry.contract),
                      child: Text(
                        truncateText(
                          widget.invokeContractEntry.contract,
                          maxLength: 20,
                        ),
                        style: context.theme.typography.body.md,
                      ),
                    ),
                  ),
                  FTooltip(
                    tipBuilder: (context, controller) => Text(loc.copy),
                    child: FButton.icon(
                      onPress: () => copyToClipboard(
                        widget.invokeContractEntry.contract,
                        ref,
                        loc.copied,
                      ),
                      child: const Icon(FLucideIcons.copy, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            LabeledValue.text(
              loc.fee,
              formatXelis(widget.invokeContractEntry.fee, network),
            ),
            LabeledValue.text(
              loc.chunk_id,
              widget.invokeContractEntry.chunkId.toString(),
            ),
            FDivider(style: .delta(padding: .add(.zero))),
            // This view intentionally stays on the wallet-authored invocation
            // projection. Full execution logs remain a daemon RPC concern.
            Column(
              spacing: Spaces.medium,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.deposits,
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    FItemGroup.builder(
                      count: widget.invokeContractEntry.deposits.length,
                      itemBuilder: (context, index) {
                        final deposit =
                            widget.invokeContractEntry.deposits[index];

                        final formattedData = getFormattedAssetNameAndAmount(
                          allAssets,
                          deposit.asset,
                          deposit.amount,
                        );
                        final assetName = formattedData.$1;
                        final amount = formattedData.$2;

                        return FItem(
                          title: AssetNameWidget(
                            assetName: assetName,
                            isXelis: isXelis(deposit.asset),
                          ),
                          details: SelectableText(amount),
                        );
                      },
                    ),
                  ],
                ),
                if (widget.invokeContractEntry.received.isNotEmpty)
                  ContractAssetTransfers(
                    title: loc.received,
                    transfers: widget.invokeContractEntry.received,
                    knownAssets: allAssets,
                    loc: loc,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
