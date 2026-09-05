import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_value_presentation.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;
import 'package:forui/forui.dart';

class InvokeWidget extends ConsumerStatefulWidget {
  const InvokeWidget({
    required this.maxGas,
    this.entryId,
    this.deposits,
    this.parameters,
    super.key,
  });

  final BigInt maxGas;
  final int? entryId;
  final Map<String, sdk.ContractDepositBuilder>? deposits;
  final List<sdk.RpcValueCell>? parameters;

  @override
  ConsumerState<InvokeWidget> createState() => _InvokeState();
}

class _InvokeState extends ConsumerState<InvokeWidget>
    with TransactionBuilderMixin {
  static const _visibleParameterLimit = 24;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabeledText(
          context,
          loc.max_gas,
          formatBigInt(widget.maxGas, locale: loc.localeName),
        ),
        if (widget.entryId != null) ...[
          buildLabeledText(context, loc.entry_id, widget.entryId.toString()),
        ],
        if (widget.deposits != null) ...[
          const SizedBox(height: Spaces.small),
          Text(
            loc.deposits,
            style: context.bodyMedium!.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          _buildDepositsList(loc, widget.deposits!, knownAssets, network),
        ],
        if (widget.parameters != null && widget.parameters!.isNotEmpty) ...[
          const SizedBox(height: Spaces.small),
          Text(
            loc.parameters,
            style: context.bodyMedium!.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          _buildParametersList(loc, widget.parameters!),
        ],
      ],
    );
  }

  Widget _buildDepositsList(
    AppLocalizations loc,
    Map<String, sdk.ContractDepositBuilder> deposits,
    Map<String, wallet_flutter.XelisWalletAssetMetadata> knownAssets,
    wallet_flutter.XelisNetwork network,
  ) {
    return Wrap(
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: deposits.entries.map((entry) {
        String ticker;
        String amount;
        final fullAssetHash = entry.key;

        // Get asset data - check known assets first (includes native asset with correct ticker)
        if (knownAssets.containsKey(entry.key)) {
          final assetData = knownAssets[entry.key]!;
          ticker = assetData.ticker;
          amount = formatCoin(
            entry.value.amount,
            assetData.decimals,
            assetData.ticker,
          );
        } else {
          // Keep an unknown asset unambiguous while bounding the chip width.
          ticker = xswdAbbreviateIdentifier(entry.key);
          amount = entry.value.amount.toString();
        }

        // Remove ticker from amount if it's already there (formatCoin adds it)
        final tickerPattern = RegExp('\\s+${RegExp.escape(ticker)}\$');
        amount = amount.replaceAll(tickerPattern, '');

        final assetLabel = knownAssets.containsKey(entry.key)
            ? ticker
            : '$ticker (${loc.unknown_asset})';
        final displayText =
            '${amount.trim()} $assetLabel${entry.value.private ? ' (${loc.private})' : ''}';

        return FTappable(
          semanticsTooltip: loc.more_details,
          onPress: () => _showDepositDetails(
            context,
            loc,
            fullAssetHash,
            ticker,
            entry.value,
            amount.trim(),
          ),
          builder: (context, states, child) => DecoratedBox(
            decoration: BoxDecoration(
              color:
                  states.contains(FTappableVariant.hovered) ||
                      states.contains(FTappableVariant.pressed)
                  ? context.theme.colors.secondary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
          child: Chip(
            label: Text(displayText, style: context.bodySmall),
            avatar: const Icon(FLucideIcons.coins, size: 16),
          ),
        );
      }).toList(),
    );
  }

  void _showDepositDetails(
    BuildContext context,
    AppLocalizations loc,
    String assetHash,
    String ticker,
    sdk.ContractDepositBuilder deposit,
    String formattedAmount,
  ) {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Row(
          children: [
            const Icon(FLucideIcons.coins),
            const SizedBox(width: Spaces.small),
            Expanded(child: Text('${loc.deposits} - $ticker')),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(loc.amount, '$formattedAmount $ticker'),
              const SizedBox(height: Spaces.small),
              _buildDetailRow(loc.raw_amount, deposit.amount.toString()),
              const SizedBox(height: Spaces.small),
              _buildDetailRow(loc.asset, assetHash),
              const SizedBox(height: Spaces.small),
              _buildDetailRow(
                loc.privacy,
                deposit.private ? loc.private : loc.public,
              ),
            ],
          ),
        ),
        actions: [
          FButton(onPress: () => context.pop(), child: Text(loc.close)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(value, style: context.bodySmall),
      ],
    );
  }

  Widget _buildParametersList(
    AppLocalizations loc,
    List<sdk.RpcValueCell> parameters,
  ) {
    final visibleCount = parameters.length.clamp(0, _visibleParameterLimit);
    return Wrap(
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: [
        for (var index = 0; index < visibleCount; index++)
          _buildParameterChip(loc, index, parameters[index]),
        if (parameters.length > visibleCount)
          FButton(
            key: const ValueKey('xswd-all-parameters'),
            onPress: () => _showAllParameters(context, loc, parameters),
            child: Text(
              '${loc.more_details} '
              '(${loc.item_count(parameters.length - visibleCount)})',
            ),
          ),
      ],
    );
  }

  Widget _buildParameterChip(
    AppLocalizations loc,
    int index,
    sdk.RpcValueCell parameter,
  ) {
    final preview = xswdRpcValuePreview(loc, parameter);
    return FTappable(
      semanticsTooltip: loc.more_details,
      onPress: () => _showParameterDetails(context, index, parameter),
      builder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              states.contains(FTappableVariant.hovered) ||
                  states.contains(FTappableVariant.pressed)
              ? context.theme.colors.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
      child: Chip(
        key: ValueKey('xswd-parameter-$index'),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preview.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall?.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      preview.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall,
                    ),
                  ],
                ),
              ),
              if (preview.isTruncated) ...[
                const SizedBox(width: Spaces.extraSmall),
                Icon(
                  FLucideIcons.info,
                  size: 14,
                  color: context.theme.colors.mutedForeground,
                ),
              ],
            ],
          ),
        ),
        avatar: const Icon(FLucideIcons.squareCode, size: 16),
      ),
    );
  }

  void _showAllParameters(
    BuildContext context,
    AppLocalizations loc,
    List<sdk.RpcValueCell> parameters,
  ) {
    showAppDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) => AppDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Text('${loc.parameters} (${parameters.length})'),
        body: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(dialogContext).height * 0.55,
          child: ListView.separated(
            itemCount: parameters.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spaces.small),
            itemBuilder: (_, index) {
              final parameter = parameters[index];
              final preview = xswdRpcValuePreview(loc, parameter);
              return FTappable(
                semanticsTooltip: loc.more_details,
                onPress: () {
                  Navigator.of(dialogContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showParameterDetails(this.context, index, parameter);
                    }
                  });
                },
                builder: (context, states, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        states.contains(FTappableVariant.hovered) ||
                            states.contains(FTappableVariant.pressed)
                        ? context.theme.colors.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Spaces.small),
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.small),
                  child: Row(
                    children: [
                      Text('${index + 1}.', style: context.bodySmall),
                      const SizedBox(width: Spaces.small),
                      Expanded(
                        child: Text(
                          '${preview.type}: ${preview.text}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall,
                        ),
                      ),
                      const Icon(FLucideIcons.chevronRight, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  void _showParameterDetails(
    BuildContext context,
    int index,
    sdk.RpcValueCell parameter,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final preview = xswdRpcValuePreview(loc, parameter);

    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => _ParameterDetailsDialog(
        style: style,
        animation: animation,
        loc: loc,
        index: index,
        type: preview.type,
        parameter: parameter,
      ),
    );
  }
}

class _ParameterDetailsDialog extends StatefulWidget {
  const _ParameterDetailsDialog({
    required this.style,
    required this.animation,
    required this.loc,
    required this.index,
    required this.type,
    required this.parameter,
  });

  final FDialogStyleDelta style;
  final Animation<double> animation;
  final AppLocalizations loc;
  final int index;
  final String type;
  final sdk.RpcValueCell parameter;

  @override
  State<_ParameterDetailsDialog> createState() =>
      _ParameterDetailsDialogState();
}

class _ParameterDetailsDialogState extends State<_ParameterDetailsDialog> {
  bool _showRawJson = false;

  @override
  Widget build(BuildContext context) {
    final content = _showRawJson
        ? xswdSerializeRpcValue(widget.parameter)
        : xswdFormatRpcValue(widget.parameter);
    return AppDialog(
      style: widget.style,
      animation: widget.animation,
      direction: Axis.horizontal,
      title: Row(
        children: [
          const Icon(FLucideIcons.squareCode),
          const SizedBox(width: Spaces.small),
          Text(widget.loc.parameter_number(widget.index + 1)),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: widget.loc.type, value: widget.type),
          const SizedBox(height: Spaces.small),
          Text(
            _showRawJson ? widget.loc.raw_json : widget.loc.value,
            style: context.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: XswdFullValueView(
              value: content,
              key: const ValueKey('xswd-parameter-full-value'),
              chunkKeyPrefix: _showRawJson
                  ? 'xswd-parameter-raw'
                  : 'xswd-parameter-value',
              monospace: _showRawJson,
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          key: const ValueKey('xswd-parameter-format-toggle'),
          onPress: () => setState(() => _showRawJson = !_showRawJson),
          child: Text(_showRawJson ? widget.loc.value : widget.loc.raw_json),
        ),
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(widget.loc.close),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(height: Spaces.extraSmall),
      SelectableText(value, style: context.bodySmall),
    ],
  );
}
