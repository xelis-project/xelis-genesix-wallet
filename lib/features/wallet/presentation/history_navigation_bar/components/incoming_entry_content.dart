import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class IncomingEntryContent extends ConsumerWidget {
  const IncomingEntryContent(this.incomingEntry, {super.key});

  final IncomingEntry incomingEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final hideZeroTransfer = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideZeroTransfer,
      ),
    );
    final hideExtraData = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideExtraData,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.from,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        AddressWidget(incomingEntry.from),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.transfers,
          style: context.titleSmall?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const Divider(),
        Builder(
          builder: (BuildContext context) {
            var transfers = incomingEntry.transfers;

            if (hideZeroTransfer) {
              transfers = transfers
                  .skipWhile((value) {
                    return value.amount == 0;
                  })
                  .toList(growable: false);
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: transfers.length,
              itemBuilder: (BuildContext context, int index) {
                final transfer = transfers[index];
                final isXelis = transfer.asset == xelisAsset;
                final xelisImagePath =
                    AppResources.greenBackgroundBlackIconPath;

                String asset;
                String amount;
                if (knownAssets.containsKey(transfer.asset)) {
                  final assetData = knownAssets[transfer.asset]!;
                  asset = assetData.name;
                  amount =
                      '+${formatCoin(transfer.amount, assetData.decimals, assetData.ticker)}';
                } else {
                  asset = truncateText(transfer.asset, maxLength: 20);
                  amount = '+${transfer.amount.toString()}';
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spaces.medium,
                      Spaces.small,
                      Spaces.medium,
                      Spaces.small,
                    ),
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
                        if (!hideExtraData && transfer.extraData != null) ...[
                          const SizedBox(height: Spaces.medium),
                          Column(
                            children: [
                              Text(
                                loc.extra_data,
                                style: context.labelMedium?.copyWith(
                                  color: context.moreColors.mutedColor,
                                ),
                              ),
                              SelectableText(transfer.extraData.toString()),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
