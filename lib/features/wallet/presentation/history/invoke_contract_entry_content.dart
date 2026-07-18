import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;

class InvokeContractEntryContent extends ConsumerStatefulWidget {
  const InvokeContractEntryContent(
    this.invokeContractEntry,
    this.transactionEntry, {
    super.key,
  });

  final InvokeContractEntry invokeContractEntry;
  final TransactionEntry transactionEntry;

  @override
  ConsumerState<InvokeContractEntryContent> createState() =>
      _InvokeContractEntryContentState();
}

class _InvokeContractEntryContentState
    extends ConsumerState<InvokeContractEntryContent> {
  final Map<String, AssetData> _fetchedAssets = {};
  List<Map<String, dynamic>> _contractLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final walletState = ref.read(walletRuntimeProvider);
    final knownAssets = walletState.knownAssets;
    final repository = ref.read(activeWalletRepositoryProvider);

    if (repository == null) {
      setState(() => _isLoading = false);
      return;
    }

    for (final assetHash in widget.invokeContractEntry.deposits.keys) {
      if (!knownAssets.containsKey(assetHash)) {
        try {
          final assetData = await repository.getAssetMetadata(assetHash);
          _fetchedAssets[assetHash] = assetData;
        } catch (e) {
          // Metadata fetch is best-effort; unknown assets keep the fallback label.
        }
      }
    }

    try {
      final logs = await repository.getContractLogs(
        widget.transactionEntry.hash,
      );
      _contractLogs = logs;

      for (final log in logs) {
        // final type = log['type'] as String;
        final value = log['value'];

        if (value is Map<String, dynamic> && value.containsKey('asset')) {
          final asset = value['asset'] as String;

          if (!knownAssets.containsKey(asset) &&
              !_fetchedAssets.containsKey(asset)) {
            try {
              final assetData = await repository.getAssetMetadata(asset);
              _fetchedAssets[asset] = assetData;
            } catch (e) {
              // Metadata fetch is best-effort; unknown assets keep the fallback label.
            }
          }
        }
      }
    } catch (e) {
      talker.error('Failed to fetch contract logs: $e');
    }

    setState(() => _isLoading = false);
  }

  Widget _buildLogWidget(
    BuildContext context,
    Map<String, dynamic> log,
    Map<String, AssetData> allAssets,
    rust.Network network,
    AppLocalizations loc,
  ) {
    final type = log['type'] as String;
    final value = log['value'];

    String header;
    Widget? details;

    switch (type) {
      case 'transfer':
        header = loc.log_transfer;
        final data = value as Map<String, dynamic>;
        final asset = data['asset'] as String;
        final amount = data['amount'];
        final destination = data['destination'] as String;

        final formattedData = getFormattedAssetNameAndAmount(
          allAssets,
          asset,
          amount,
        );

        details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.extraSmall,
          children: [
            Row(
              children: [
                Expanded(
                  child: AssetNameWidget(
                    assetName: formattedData.$1,
                    isXelis: isXelis(asset),
                  ),
                ),
                SelectableText(
                  formattedData.$2,
                  style: context.theme.typography.body.md,
                ),
              ],
            ),
            Text(
              loc.to_address(truncateText(destination, maxLength: 20)),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        );
        break;

      case 'transfer_contract':
        header = loc.log_transfer_to_contract;
        final data = value as Map<String, dynamic>;
        final asset = data['asset'] as String;
        final amount = data['amount'];
        final destination = data['destination'] as String;

        final formattedData = getFormattedAssetNameAndAmount(
          allAssets,
          asset,
          amount,
        );

        details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.extraSmall,
          children: [
            Row(
              children: [
                Expanded(
                  child: AssetNameWidget(
                    assetName: formattedData.$1,
                    isXelis: isXelis(asset),
                  ),
                ),
                SelectableText(
                  formattedData.$2,
                  style: context.theme.typography.body.md,
                ),
              ],
            ),
            Text(
              loc.to_contract_address(truncateText(destination, maxLength: 16)),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        );
        break;

      case 'burn':
        header = loc.burn;
        final data = value as Map<String, dynamic>;
        final asset = data['asset'] as String;
        final amount = data['amount'];

        final formattedData = getFormattedAssetNameAndAmount(
          allAssets,
          asset,
          amount,
        );

        details = Row(
          children: [
            Expanded(
              child: AssetNameWidget(
                assetName: formattedData.$1,
                isXelis: isXelis(asset),
              ),
            ),
            SelectableText(
              formattedData.$2,
              style: context.theme.typography.body.md,
            ),
          ],
        );
        break;

      case 'mint':
        header = loc.log_mint;
        final data = value as Map<String, dynamic>;
        final asset = data['asset'] as String;
        final amount = data['amount'];

        final formattedData = getFormattedAssetNameAndAmount(
          allAssets,
          asset,
          amount,
        );

        details = Row(
          children: [
            Expanded(
              child: AssetNameWidget(
                assetName: formattedData.$1,
                isXelis: isXelis(asset),
              ),
            ),
            SelectableText(
              formattedData.$2,
              style: context.theme.typography.body.md,
            ),
          ],
        );
        break;

      case 'refund_gas':
        header = loc.log_gas_refund;
        final data = value as Map<String, dynamic>;
        final amount = data['amount'];

        details = SelectableText(
          formatXelis(amount, network),
          style: context.theme.typography.body.md,
        );
        break;

      case 'exit_code':
        header = loc.log_exit_code;
        final exitCodeValue = value as int?;
        details = SelectableText(
          exitCodeValue?.toString() ?? loc.log_failed,
          style: context.theme.typography.body.md.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
        break;

      case 'new_asset':
        header = loc.log_new_asset;
        final data = value as Map<String, dynamic>;
        final assetHash = data['asset'] as String?;
        final name = data['name'] as String?;
        final ticker = data['ticker'] as String?;
        final decimals = data['decimals'] as int?;

        details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.extraSmall,
          children: [
            if (name != null) LabeledValue.text(loc.name, name),
            if (ticker != null) LabeledValue.text(loc.ticker, ticker),
            if (decimals != null)
              LabeledValue.text(loc.decimals, decimals.toString()),
            if (assetHash != null)
              LabeledValue.text(
                loc.asset,
                truncateText(assetHash, maxLength: 20),
              ),
          ],
        );
        break;

      default:
        header = type.capitalize();
        details = Text(
          value?.toString() ?? 'N/A',
          style: context.theme.typography.body.md,
        );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: context.theme.colors.primary, width: 2),
        ),
      ),
      padding: const EdgeInsets.only(
        left: Spaces.small,
        top: Spaces.extraSmall,
        bottom: Spaces.extraSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spaces.extraSmall,
        children: [
          Text(
            header,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          DefaultTextStyle.merge(
            style: context.theme.typography.body.md,
            child: details,
          ),
        ],
      ),
    );
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
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
                          final deposit = widget
                              .invokeContractEntry
                              .deposits
                              .entries
                              .elementAt(index);

                          final formattedData = getFormattedAssetNameAndAmount(
                            allAssets,
                            deposit.key,
                            deposit.value,
                          );
                          final assetName = formattedData.$1;
                          final amount = formattedData.$2;

                          return FItem(
                            title: AssetNameWidget(
                              assetName: assetName,
                              isXelis: isXelis(deposit.key),
                            ),
                            details: SelectableText(amount),
                          );
                        },
                      ),
                    ],
                  ),
                  if (widget.invokeContractEntry.received.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.received,
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        FItemGroup.builder(
                          count: widget.invokeContractEntry.received.length,
                          itemBuilder: (context, index) {
                            final received = widget
                                .invokeContractEntry
                                .received
                                .entries
                                .elementAt(index);

                            final formattedData =
                                getFormattedAssetNameAndAmount(
                                  allAssets,
                                  received.key,
                                  received.value,
                                );
                            final assetName = formattedData.$1;
                            final amount = formattedData.$2;

                            return FItem(
                              title: AssetNameWidget(
                                assetName: assetName,
                                isXelis: isXelis(received.key),
                              ),
                              details: SelectableText(amount),
                            );
                          },
                        ),
                      ],
                    ),
                  if (_contractLogs.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Spaces.small,
                      children: [
                        Text(
                          loc.contract_logs,
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        ..._contractLogs.map(
                          (log) => _buildLogWidget(
                            context,
                            log,
                            allAssets,
                            network,
                            loc,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
