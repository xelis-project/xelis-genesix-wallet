import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class InvokeWidget extends ConsumerStatefulWidget {
  const InvokeWidget({
    required this.maxGas,
    required this.chunkId,
    required this.deposits,
    required this.parameters,
    super.key,
  });

  final int maxGas;
  final int chunkId;
  final Map<String, sdk.ContractDepositBuilder> deposits;
  final List<dynamic> parameters;

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
        buildLabeledText(context, loc.entry_id, widget.chunkId.toString()),
        const SizedBox(height: Spaces.small),
        Text(
          loc.deposits,
          style: context.bodyMedium!.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        _buildDepositsList(loc, widget.deposits, knownAssets, network),
        if (widget.parameters.isNotEmpty) ...[
          const SizedBox(height: Spaces.small),
          Text(
            loc.parameters,
            style: context.bodyMedium!.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          _buildParametersList(widget.parameters),
        ],
      ],
    );
  }

  Widget _buildDepositsList(
    AppLocalizations loc,
    Map<String, sdk.ContractDepositBuilder> deposits,
    Map<String, AssetData> knownAssets,
    rust.Network network,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: deposits.entries.map((entry) {
        String asset;
        String amount;
        if (entry.key == sdk.xelisAsset) {
          asset = AppResources.xelisName;
          amount = formatXelis(entry.value.amount, network);
        } else if (knownAssets.containsKey(entry.key)) {
          final assetData = knownAssets[entry.key]!;
          asset = assetData.name;
          amount = formatCoin(
            entry.value.amount,
            assetData.decimals,
            assetData.ticker,
          );
        } else {
          asset = entry.key;
          amount = entry.value.amount.toString();
        }

        if (entry.value.private) {
          amount += ' (${loc.private})';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spaces.small),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spaces.small),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${loc.asset.toLowerCase()}:',
                    style: context.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.moreColors.mutedColor,
                    ),
                  ),
                  const SizedBox(width: Spaces.extraSmall),
                  Expanded(child: Text(asset, style: context.bodySmall)),
                ],
              ),
              const SizedBox(height: Spaces.extraSmall),
              Row(
                children: [
                  Text(
                    '${loc.amount.toLowerCase()}:',
                    style: context.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.moreColors.mutedColor,
                    ),
                  ),
                  const SizedBox(width: Spaces.extraSmall),
                  Text(amount, style: context.bodySmall),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParametersList(List<dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spaces.small),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spaces.small),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map((e) {
          final encoded = const JsonEncoder.withIndent('  ').convert(e);
          return SelectableText(encoded, style: context.bodySmall);
        }).toList(),
      ),
    );
  }
}
