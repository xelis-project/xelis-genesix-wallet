import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;
import 'package:forui/forui.dart';

class InvokeWidget extends ConsumerStatefulWidget {
  const InvokeWidget({
    required this.maxGas,
    this.entryId,
    this.deposits,
    this.parameters,
    super.key,
  });

  final int maxGas;
  final int? entryId;
  final Map<String, sdk.ContractDepositBuilder>? deposits;
  final List<dynamic>? parameters;

  @override
  ConsumerState<InvokeWidget> createState() => _InvokeState();
}

class _InvokeState extends ConsumerState<InvokeWidget>
    with TransactionBuilderMixin {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabeledText(
          context,
          loc.max_gas,
          formatXelis(widget.maxGas, network),
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
          _buildParametersList(widget.parameters!),
        ],
      ],
    );
  }

  Widget _buildDepositsList(
    AppLocalizations loc,
    Map<String, sdk.ContractDepositBuilder> deposits,
    Map<String, sdk.AssetData> knownAssets,
    rust.Network network,
  ) {
    return Wrap(
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: deposits.entries.map((entry) {
        String ticker;
        String amount;
        String fullAssetHash = entry.key;

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
          // Unknown asset - use hash prefix as ticker
          ticker = entry.key.substring(0, 8);
          amount = entry.value.amount.toString();
        }

        // Remove ticker from amount if it's already there (formatCoin adds it)
        final tickerPattern = RegExp('\\s+${RegExp.escape(ticker)}\$');
        amount = amount.replaceAll(tickerPattern, '');

        final displayText =
            '${amount.trim()} $ticker${entry.value.private ? ' (${loc.private})' : ''}';

        return InkWell(
          onTap: () => _showDepositDetails(
            context,
            loc,
            fullAssetHash,
            ticker,
            entry.value,
            amount.trim(),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Chip(
            label: Text(displayText, style: context.bodySmall),
            avatar: const Icon(Icons.currency_exchange, size: 16),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.currency_exchange),
            const SizedBox(width: Spaces.small),
            Expanded(child: Text('${loc.deposits} - $ticker')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(loc.amount, '$formattedAmount $ticker'),
              const SizedBox(height: Spaces.small),
              _buildDetailRow('Raw ${loc.amount}', deposit.amount.toString()),
              const SizedBox(height: Spaces.small),
              _buildDetailRow(loc.asset, assetHash),
              const SizedBox(height: Spaces.small),
              _buildDetailRow(
                'Privacy',
                deposit.private ? loc.private : 'Public',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(loc.close)),
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

  Widget _buildParametersList(List<dynamic> data) {
    return Wrap(
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final param = entry.value;

        // Deserialize to structured ParsedValue
        final parsed = sdk.deserializeValueCell(param);

        // Format for display
        final formatted = _formatParsedValue(parsed);
        final isTruncated = _isTruncatedValue(parsed);

        return InkWell(
          onTap: () => _showParameterDetails(context, index, param, parsed),
          borderRadius: BorderRadius.circular(8),
          child: Chip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTypeDisplay(parsed),
                      style: context.bodySmall?.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                    Text(formatted, style: context.bodySmall),
                  ],
                ),
                if (isTruncated) ...[
                  const SizedBox(width: Spaces.extraSmall),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.theme.colors.mutedForeground,
                  ),
                ],
              ],
            ),
            avatar: const Icon(Icons.data_object, size: 16),
          ),
        );
      }).toList(),
    );
  }

  String _formatParsedValue(sdk.ParsedValue parsed) {
    // Handle option
    if (parsed is sdk.ParsedOption) {
      if (parsed.isNone) return 'None';
      return 'Some(${_formatParsedValue(parsed.unwrap())})';
    }

    // Handle array
    if (parsed is sdk.ParsedArray) {
      if (parsed.length == 0) return '[]';
      if (parsed.length <= 3) {
        final items = parsed.items.map(_formatParsedValue).join(', ');
        return '[$items]';
      }
      return '[${parsed.length} items]';
    }

    // Handle map
    if (parsed is sdk.ParsedMap) {
      if (parsed.length == 0) return '{}';
      if (parsed.length == 1) {
        final entry = parsed.entries.entries.first;
        return '{${_formatValue(entry.key)}: ${_formatValue(entry.value)}}';
      }
      return '{${parsed.length} entries}';
    }

    // Handle primitives
    if (parsed is sdk.ParsedPrimitive) {
      final value = parsed.value;

      if (parsed.isString) {
        final str = value.toString();
        if (str.length > 30) {
          return '"${str.substring(0, 30)}..."';
        }
        return '"$str"';
      }

      if (parsed.isHash || parsed.isAddress) {
        final str = value.toString();
        if (str.length > 16) {
          return '${str.substring(0, 8)}...${str.substring(str.length - 6)}';
        }
        return str;
      }

      if (parsed.type == 'u128' || parsed.type == 'u256') {
        final str = value.toString();
        if (str.length > 20) {
          return '${str.substring(0, 20)}...';
        }
        return str;
      }

      return value.toString();
    }

    return parsed.value.toString();
  }

  String _formatValue(dynamic value) {
    if (value is sdk.ParsedValue) {
      return _formatParsedValue(value);
    }
    return value.toString();
  }

  bool _isTruncatedValue(sdk.ParsedValue parsed) {
    // Handle option
    if (parsed is sdk.ParsedOption) {
      if (parsed.isNone) return false;
      return _isTruncatedValue(parsed.unwrap());
    }

    // Handle array
    if (parsed is sdk.ParsedArray) {
      return parsed.length > 3;
    }

    // Handle map
    if (parsed is sdk.ParsedMap) {
      return parsed.length > 1;
    }

    // Handle primitives
    if (parsed is sdk.ParsedPrimitive) {
      final value = parsed.value;

      if (parsed.isString) {
        return value.toString().length > 30;
      }

      if (parsed.isHash || parsed.isAddress) {
        return value.toString().length > 16;
      }

      if (parsed.type == 'u128' || parsed.type == 'u256') {
        return value.toString().length > 20;
      }
    }

    return false;
  }

  void _showParameterDetails(
    BuildContext context,
    int index,
    dynamic param,
    sdk.ParsedValue parsed,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(param);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_object),
            const SizedBox(width: Spaces.small),
            Text('Parameter #${index + 1}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', _getTypeDisplay(parsed)),
              const SizedBox(height: Spaces.small),
              _buildDetailRow('Value', _getFullValueDisplay(parsed)),
              const SizedBox(height: Spaces.medium),
              Text(
                'Raw JSON',
                style: context.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spaces.small),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spaces.small),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: SelectableText(
                  jsonString,
                  style: context.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(loc.close)),
        ],
      ),
    );
  }

  String _getTypeDisplay(sdk.ParsedValue parsed) {
    if (parsed is sdk.ParsedMap) {
      return 'map<${parsed.keyType}, ${parsed.valueType}>';
    }
    return parsed.type;
  }

  String _getFullValueDisplay(sdk.ParsedValue parsed) {
    if (parsed is sdk.ParsedOption) {
      if (parsed.isNone) return 'None';
      return 'Some(${_getFullValueDisplay(parsed.unwrap())})';
    }

    if (parsed is sdk.ParsedArray) {
      if (parsed.length == 0) return '[]';
      final items = parsed.items.map(_getFullValueDisplay).join(', ');
      return '[$items]';
    }

    if (parsed is sdk.ParsedMap) {
      if (parsed.length == 0) return '{}';
      final entries = parsed.entries.entries
          .map((e) {
            final key = e.key;
            final val = e.value is sdk.ParsedValue
                ? _getFullValueDisplay(e.value as sdk.ParsedValue)
                : e.value.toString();
            return '$key: $val';
          })
          .join(', ');
      return '{$entries}';
    }

    if (parsed is sdk.ParsedPrimitive) {
      if (parsed.isString) {
        return '"${parsed.value}"';
      }
      return parsed.value.toString();
    }

    return parsed.value.toString();
  }
}
