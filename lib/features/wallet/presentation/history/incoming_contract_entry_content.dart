import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class IncomingContractEntryContent extends ConsumerWidget {
  const IncomingContractEntryContent(this.incomingContractEntry, {super.key});

  final IncomingContractEntry incomingContractEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
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
            Text(
              loc.transfers,
              style: context.theme.typography.base.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            FItemGroup.builder(
              count: incomingContractEntry.transfers.length,
              itemBuilder: (context, index) {
                final transfer = incomingContractEntry.transfers.entries
                    .elementAt(index);

                final formattedData = getFormattedAssetNameAndAmount(
                  knownAssets,
                  transfer.key,
                  transfer.value,
                );
                final assetName = formattedData.$1;
                final amount = formattedData.$2;

                return FItem(
                  title: AssetNameWidget(
                    assetName: assetName,
                    isXelis: isXelis(transfer.key),
                  ),
                  details: SelectableText(amount),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
