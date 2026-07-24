import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ContractAssetTransfers extends StatelessWidget {
  const ContractAssetTransfers({
    required this.title,
    required this.transfers,
    required this.knownAssets,
    required this.loc,
    super.key,
  });

  final String title;
  final Map<String, Map<String, int>> transfers;
  final Map<String, AssetData> knownAssets;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final rows = _flattenContractTransfers(transfers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        if (rows.isEmpty)
          Text(loc.no_transfers_found)
        else
          FItemGroup.builder(
            count: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final formattedData = getFormattedAssetNameAndAmount(
                knownAssets,
                row.asset,
                row.amount,
              );

              return FItem(
                title: AssetNameWidget(
                  assetName: formattedData.$1,
                  isXelis: isXelis(row.asset),
                ),
                subtitle: SelectableText('${loc.contract}: ${row.contract}'),
                details: SelectableText(formattedData.$2),
              );
            },
          ),
      ],
    );
  }
}

List<_ContractTransferRow> _flattenContractTransfers(
  Map<String, Map<String, int>> transfers,
) {
  return [
    for (final contractEntry in transfers.entries)
      for (final assetEntry in contractEntry.value.entries)
        _ContractTransferRow(
          contract: contractEntry.key,
          asset: assetEntry.key,
          amount: assetEntry.value,
        ),
  ];
}

class _ContractTransferRow {
  const _ContractTransferRow({
    required this.contract,
    required this.asset,
    required this.amount,
  });

  final String contract;
  final String asset;
  final int amount;
}
