import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class InvokeContractEntryContent extends ConsumerWidget {
  const InvokeContractEntryContent(this.invokeContractEntry, {super.key});

  final InvokeContractEntry invokeContractEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            LabeledValue.text(loc.contract, invokeContractEntry.contract),
            LabeledValue.text(
              loc.fee,
              formatXelis(invokeContractEntry.fee, network),
            ),
            LabeledValue.text(
              loc.entry_id,
              invokeContractEntry.chunkId.toString(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.deposits,
                  style: context.theme.typography.base.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                FItemGroup.builder(
                  itemBuilder: (context, index) {
                    final deposit = invokeContractEntry.deposits.entries
                        .elementAt(index);

                    final formattedData = getFormattedAssetNameAndAmount(
                      knownAssets,
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
          ],
        ),
      ),
    );
  }
}
