import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
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
  final Map<String, dynamic> deposits;
  final List<dynamic> parameters;

  @override
  ConsumerState<InvokeWidget> createState() => _InvokeState();
}

class _InvokeState extends ConsumerState<InvokeWidget>
    with TransactionBuilderMixin {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabeledText(context, loc.max_gas, formatXelis(widget.maxGas)),
        buildLabeledText(context, loc.entry_id, widget.chunkId.toString()),
        const SizedBox(height: Spaces.small),
        Text(
          loc.deposits,
          style: context.bodyMedium!.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        _buildDepositsList(loc, widget.deposits),
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
    Map<String, dynamic> deposits,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          deposits.entries.map((entry) {
            final isXelisAsset = entry.key == AppResources.xelisAsset.hash;
            final asset =
                isXelisAsset ? AppResources.xelisAsset.name : entry.key;

            String amount;
            if ((entry.value as ContractDepositBuilder).private) {
              amount = "${entry.value.toString()} (${loc.private})";
            } else {
              if (isXelisAsset) {
                amount = formatXelis(
                  (entry.value as ContractDepositBuilder).amount,
                );
              } else {
                amount = entry.value.toString();
              }
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
                      Text(asset, style: context.bodySmall),
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
        children:
            data.map((e) {
              final encoded = const JsonEncoder.withIndent('  ').convert(e);
              return SelectableText(encoded, style: context.bodySmall);
            }).toList(),
      ),
    );
  }
}
