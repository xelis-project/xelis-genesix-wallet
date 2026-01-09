import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

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
    final knownAssets = ref.read(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final repository = ref.read(walletStateProvider).nativeWalletRepository;

    if (repository == null) {
      setState(() => _isLoading = false);
      return;
    }

    for (final assetHash in widget.invokeContractEntry.deposits.keys) {
      if (!knownAssets.containsKey(assetHash)) {
        try {
          final assetData = await repository.getAssetMetadata(assetHash);
          _fetchedAssets[assetHash] = assetData;
        } catch (e) {}
      }
    }

    try {
      final logs = await repository.getContractLogs(widget.transactionEntry.hash);
      _contractLogs = logs;

      for (final log in logs) {
        final type = log['type'] as String;
        final value = log['value'];

        if (value is Map<String, dynamic> && value.containsKey('asset')) {
          final asset = value['asset'] as String;

          if (!knownAssets.containsKey(asset) &&
              !_fetchedAssets.containsKey(asset)) {
            try {
              final assetData = await repository.getAssetMetadata(asset);
              _fetchedAssets[asset] = assetData;
            } catch (e) {}
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
) {
  final type = log['type'] as String;
  final value = log['value'];

  String header;
  Widget? details;

  switch (type) {
    case 'transfer':
      header = 'Transfer';
      final data = value as Map<String, dynamic>;
      final asset = data['asset'] as String;
      final amount = data['amount'] as int;
      final destination = data['destination'] as String;

      final formattedData =
          getFormattedAssetNameAndAmount(allAssets, asset, amount);

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
                style: context.theme.typography.base,
              ),
            ],
          ),
          Text(
            'To: ${truncateText(destination, maxLength: 20)}',
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      );
      break;

    case 'transfer_contract':
      header = 'Transfer to Contract';
      final data = value as Map<String, dynamic>;
      final asset = data['asset'] as String;
      final amount = data['amount'] as int;
      final destination = data['destination'] as String;

      final formattedData =
          getFormattedAssetNameAndAmount(allAssets, asset, amount);

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
                style: context.theme.typography.base,
              ),
            ],
          ),
          Text(
            'To Contract: ${truncateText(destination, maxLength: 16)}',
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      );
      break;

    case 'burn':
      header = 'Burn';
      final data = value as Map<String, dynamic>;
      final asset = data['asset'] as String;
      final amount = data['amount'] as int;

      final formattedData =
          getFormattedAssetNameAndAmount(allAssets, asset, amount);

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
            style: context.theme.typography.base,
          ),
        ],
      );
      break;

    case 'mint':
      header = 'Mint';
      final data = value as Map<String, dynamic>;
      final asset = data['asset'] as String;
      final amount = data['amount'] as int;

      final formattedData =
          getFormattedAssetNameAndAmount(allAssets, asset, amount);

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
            style: context.theme.typography.base,
          ),
        ],
      );
      break;

    case 'refund_gas':
      header = 'Gas Refund';
      final data = value as Map<String, dynamic>;
      final amount = data['amount'] as int;

      details = SelectableText(
        formatCoin(amount, 8, 'XEL'),
        style: context.theme.typography.base,
      );
      break;

    case 'exit_code':
      header = 'Exit Code';
      final exitCodeValue = value as int?;
      details = SelectableText(
        exitCodeValue?.toString() ?? 'Failed',
        style: context.theme.typography.base.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
      break;

    case 'new_asset':
      header = 'New Asset';
      final data = value as Map<String, dynamic>;
      final assetHash = data['asset'] as String?;
      final name = data['name'] as String?;
      final ticker = data['ticker'] as String?;
      final decimals = data['decimals'] as int?;

      details = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spaces.extraSmall,
        children: [
          if (name != null)
            Row(
              children: [
                Text(
                  'Name: ',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    name,
                    style: context.theme.typography.sm,
                  ),
                ),
              ],
            ),
          if (ticker != null)
            Row(
              children: [
                Text(
                  'Ticker: ',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                SelectableText(
                  ticker,
                  style: context.theme.typography.sm,
                ),
              ],
            ),
          if (decimals != null)
            Row(
              children: [
                Text(
                  'Decimals: ',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                SelectableText(
                  decimals.toString(),
                  style: context.theme.typography.sm,
                ),
              ],
            ),
          if (assetHash != null)
            Row(
              children: [
                Text(
                  'Asset: ',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    truncateText(assetHash, maxLength: 20),
                    style: context.theme.typography.sm,
                  ),
                ),
              ],
            ),
        ],
      );
      break;

    default:
      header = type.capitalize();
      details = Text(
        value?.toString() ?? 'N/A',
        style: context.theme.typography.base,
      );
  }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spaces.small),
        border: Border.all(
          color: context.theme.colors.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(Spaces.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spaces.small,
        children: [
          Text(
            header,
            style: context.theme.typography.xs.copyWith(
              color: context.theme.colors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (details != null)
            DefaultTextStyle.merge(
              style: context.theme.typography.base,
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
      walletStateProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    // Merge known assets with fetched assets
    final allAssets = {...knownAssets, ..._fetchedAssets};

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            LabeledValue.text(
              loc.contract,
              widget.invokeContractEntry.contract,
            ),
            LabeledValue.text(
              loc.fee,
              formatXelis(widget.invokeContractEntry.fee, network),
            ),
            LabeledValue.text(
              'Chunk ID',
              widget.invokeContractEntry.chunkId.toString(),
            ),
            FDivider(
            style: context.theme.dividerStyles.horizontalStyle
                .copyWith(
                  padding: EdgeInsets.zero,
                  color: context.theme.colors.primary,
                )
                .call,
            ),
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
                        style: context.theme.typography.xl.copyWith(
                          color: context.theme.colors.foreground,
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
                          'Received',
                          style: context.theme.typography.xl.copyWith(
                            color: context.theme.colors.foreground,
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

                            final formattedData = getFormattedAssetNameAndAmount(
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
                          'Contract Logs',
                          style: context.theme.typography.xl.copyWith(
                            color: context.theme.colors.foreground,
                          ),
                        ),
                        ..._contractLogs.map((log) => _buildLogWidget(context, log, allAssets)),
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
