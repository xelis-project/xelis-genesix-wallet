import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/widgets/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class DeployContractEntryContent extends ConsumerWidget {
  const DeployContractEntryContent(this.deployContractEntry, {super.key});

  final DeployContractEntry deployContractEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        Text(
          loc.fee,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          formatXelis(deployContractEntry.fee, network),
          style: context.bodyLarge,
        ),
        if (deployContractEntry.invoke != null) ...[
          const SizedBox(height: Spaces.medium),
          Text(
            loc.max_gas,
            style: context.labelLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            formatXelis(deployContractEntry.invoke!.maxGas, network),
            style: context.bodyLarge,
          ),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.deposits,
            style: context.labelLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          ListView.builder(
            shrinkWrap: true,
            itemCount: deployContractEntry.invoke!.deposits.length,
            itemBuilder: (BuildContext context, int index) {
              final deposit = deployContractEntry.invoke!.deposits.entries
                  .elementAt(index);
              final isXelis = deposit.key == xelisAsset;
              final xelisImagePath = AppResources.greenBackgroundBlackIconPath;

              String asset;
              String amount;
              if (knownAssets.containsKey(deposit.key)) {
                final assetData = knownAssets[deposit.key]!;
                asset = assetData.name;
                amount = formatCoin(
                  deposit.value,
                  assetData.decimals,
                  assetData.ticker,
                );
              } else {
                asset = truncateText(deposit.key, maxLength: 20);
                amount = deposit.value.toString();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.medium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: Spaces.extraSmall,
                            ),
                            child: Text(
                              loc.asset.toLowerCase(),
                              style: context.labelMedium?.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                          ),
                          isXelis
                              ? Row(
                                  children: [
                                    Logo(imagePath: xelisImagePath),
                                    const SizedBox(width: Spaces.small),
                                    Text(AppResources.xelisName),
                                  ],
                                )
                              : SelectableText(asset),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: Spaces.extraSmall,
                            ),
                            child: Text(
                              loc.amount,
                              style: context.labelMedium?.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                          ),
                          SelectableText(amount),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
