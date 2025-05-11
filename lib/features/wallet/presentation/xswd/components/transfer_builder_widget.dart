import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class TransfersBuilderWidget extends ConsumerStatefulWidget {
  final TransfersBuilder transfersBuilder;

  const TransfersBuilderWidget({super.key, required this.transfersBuilder});

  @override
  ConsumerState<TransfersBuilderWidget> createState() =>
      _TransfersBuilderWidgetState();
}

class _TransfersBuilderWidgetState extends ConsumerState<TransfersBuilderWidget>
    with TransactionBuilderMixin {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.transfers,
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spaces.medium),
        _buildTransfersList(
          loc,
          widget.transfersBuilder.transfers,
          knownAssets,
        ),
      ],
    );
  }

  Widget _buildTransfersList(
    AppLocalizations loc,
    List<TransferBuilder> transfers,
    Map<String, AssetData> knownAssets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          transfers.map((t) {
            String asset;
            String amount;
            if (knownAssets.containsKey(t.asset)) {
              final assetData = knownAssets[t.asset]!;
              asset = assetData.name;
              amount = formatCoin(
                t.amount,
                assetData.decimals,
                assetData.ticker,
              );
            } else {
              asset = t.asset;
              amount = t.amount.toString();
            }

            final extraData = const JsonEncoder.withIndent(
              '  ',
            ).convert(t.extraData);

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
                  buildLabeledText(context, loc.asset.toLowerCase(), asset),
                  buildLabeledText(context, loc.amount.toLowerCase(), amount),
                  Text(
                    '${loc.destination.toLowerCase()}:',
                    style: context.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.moreColors.mutedColor,
                    ),
                  ),
                  AddressWidget(t.destination),
                  if (t.extraData != null) ...[
                    const SizedBox(height: Spaces.extraSmall),
                    Text(
                      loc.extra_data,
                      style: context.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.moreColors.mutedColor,
                      ),
                    ),
                    SelectableText(extraData, style: context.bodySmall),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }
}
