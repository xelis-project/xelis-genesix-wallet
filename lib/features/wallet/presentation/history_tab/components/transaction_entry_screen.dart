import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/logo.dart';
import 'package:genesix/rust_bridge/api/network.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';

class TransactionEntryScreenExtra {
  final sdk.TransactionEntry transactionEntry;

  TransactionEntryScreenExtra(this.transactionEntry);
}

class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({required this.routerState, super.key});

  final GoRouterState routerState;

  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState
    extends ConsumerState<TransactionEntryScreen> {
  late String entryTypeName;
  late Icon icon;
  sdk.CoinbaseEntry? coinbase;
  sdk.OutgoingEntry? outgoing;
  sdk.BurnEntry? burn;
  sdk.IncomingEntry? incoming;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network =
        ref.watch(settingsProvider.select((state) => state.network));
    final hideZeroTransfer =
        ref.watch(settingsProvider.select((value) => value.hideZeroTransfer));
    final hideExtraData =
        ref.watch(settingsProvider.select((value) => value.hideExtraData));

    final extra = widget.routerState.extra as TransactionEntryScreenExtra;
    final transactionEntry = extra.transactionEntry;
    final entryType = transactionEntry.txEntryType;

    String hashPath = 'txs/';
    switch (entryType) {
      case sdk.CoinbaseEntry():
        entryTypeName = loc.coinbase;
        coinbase = entryType;
        icon = Icon(
          Icons.square_rounded,
          color: context.colors.primary,
        );
        hashPath = 'blocks/';
      case sdk.BurnEntry():
        entryTypeName = loc.burn;
        burn = entryType;
        icon = Icon(
          Icons.local_fire_department_rounded,
          color: context.colors.primary,
        );
      case sdk.IncomingEntry():
        entryTypeName = loc.incoming;
        incoming = entryType;
        icon = Icon(
          Icons.arrow_downward,
          color: context.colors.primary,
        );
      case sdk.OutgoingEntry():
        entryTypeName = loc.outgoing;
        outgoing = entryType;
        icon = Icon(
          Icons.arrow_upward,
          color: context.colors.primary,
        );
    }

    Uri url;
    switch (network) {
      case Network.mainnet || Network.dev:
        url = Uri.parse(
            '${AppResources.explorerMainnetUrl}$hashPath${transactionEntry.hash}');
      case Network.testnet:
        url = Uri.parse(
            '${AppResources.explorerTestnetUrl}$hashPath${transactionEntry.hash}');
    }

    var displayTopoheight = NumberFormat().format(transactionEntry.topoHeight);

    return CustomScaffold(
      backgroundColor: Colors.transparent,
      appBar: GenericAppBar(title: loc.transaction),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Spaces.large, Spaces.none, Spaces.large, Spaces.large),
        children: [
          Text(loc.type,
              style: context.labelLarge
                  ?.copyWith(color: context.moreColors.mutedColor)),
          const SizedBox(height: Spaces.extraSmall),
          Row(
            children: [
              icon,
              const SizedBox(width: Spaces.small),
              SelectableText(
                entryTypeName,
                style: context.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: Spaces.medium),
          Text(loc.topoheight,
              style: context.labelLarge
                  ?.copyWith(color: context.moreColors.mutedColor)),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            displayTopoheight,
            style: context.bodyLarge,
          ),
          const SizedBox(height: Spaces.medium),
          Text(loc.timestamp,
              style: context.labelLarge
                  ?.copyWith(color: context.moreColors.mutedColor)),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            transactionEntry.timestamp?.toString() ?? loc.not_available,
            style: context.bodyLarge,
          ),
          const SizedBox(height: Spaces.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.hash,
                  style: context.labelLarge
                      ?.copyWith(color: context.moreColors.mutedColor)),
              IconButton(
                onPressed: () => _launchUrl(url),
                icon: const Icon(Icons.link),
                tooltip: loc.explorer,
              ),
            ],
          ),
          SelectableText(
            transactionEntry.hash,
            style: context.bodyLarge,
          ),

          // COINBASE
          if (entryType is sdk.CoinbaseEntry)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spaces.medium),
                Text(loc.amount,
                    style: context.labelLarge
                        ?.copyWith(color: context.moreColors.mutedColor)),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  // hmm coinbase could return other asset than XELIS
                  '+${formatXelis(coinbase!.reward)}',
                  style: context.bodyLarge,
                ),
              ],
            ),

          // BURN
          if (entryType is sdk.BurnEntry) ...[
            const SizedBox(height: Spaces.medium),
            Text(loc.fee,
                style: context.labelLarge
                    ?.copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              formatXelis(burn!.fee),
              style: context.bodyLarge,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spaces.medium),
                Text(loc.burn,
                    style: context.labelLarge
                        ?.copyWith(color: context.moreColors.mutedColor)),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  '-${formatXelis(burn!.amount)}',
                  style: context.bodyLarge,
                ),
              ],
            ),
          ],

          // OUTGOING
          if (entryType is sdk.OutgoingEntry) ...[
            const SizedBox(height: Spaces.medium),
            Text(loc.fee,
                style: context.labelLarge
                    ?.copyWith(color: context.moreColors.mutedColor)),
            const SizedBox(height: Spaces.extraSmall),
            SelectableText(
              formatXelis(outgoing!.fee),
              style: context.bodyLarge,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spaces.medium),
                Text(
                  loc.transfers,
                  style: context.labelLarge
                      ?.copyWith(color: context.moreColors.mutedColor),
                ),
                const Divider(),
                Builder(
                  builder: (BuildContext context) {
                    var transfers = outgoing!.transfers;

                    if (hideZeroTransfer) {
                      transfers = transfers.skipWhile((value) {
                        return value.amount == 0;
                      }).toList(growable: false);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: transfers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final transfer = transfers[index];
                        final isXelis = transfer.asset == sdk.xelisAsset;
                        final xelisPath = AppResources.xelisAsset.imagePath!;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(Spaces.medium),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    HashiconWidget(
                                      hash: transfer.destination,
                                      size: const Size(35, 35),
                                    ),
                                    const SizedBox(width: Spaces.small),
                                    Expanded(
                                      child: SelectableText(
                                        transfer.destination,
                                        style: context.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(loc.asset,
                                            style: context.labelLarge?.copyWith(
                                                color: context
                                                    .moreColors.mutedColor)),
                                        isXelis
                                            ? Row(
                                                children: [
                                                  Logo(
                                                    imagePath: xelisPath,
                                                  ),
                                                  const SizedBox(
                                                      width: Spaces.small),
                                                  Text(AppResources
                                                      .xelisAsset.name),
                                                ],
                                              )
                                            : Text(
                                                truncateText(transfer.asset)),
                                      ],
                                    ),
                                    const SizedBox(width: Spaces.medium),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(loc.amount,
                                            style: context.labelLarge?.copyWith(
                                                color: context
                                                    .moreColors.mutedColor)),
                                        SelectableText(isXelis
                                            ? '-${formatXelis(transfer.amount)}'
                                            : '${transfer.amount}'),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!hideExtraData) ...[
                                  const SizedBox(height: Spaces.medium),
                                  Text(loc.extra_data,
                                      style: context.labelLarge),
                                  SelectableText(transfer.extraData.toString()),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ],

          // INCOMING
          if (entryType is sdk.IncomingEntry)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spaces.medium),
                Text(loc.from,
                    style: context.labelLarge
                        ?.copyWith(color: context.moreColors.mutedColor)),
                const SizedBox(height: Spaces.extraSmall),
                Row(
                  children: [
                    HashiconWidget(
                      hash: incoming!.from,
                      size: const Size(35, 35),
                    ),
                    const SizedBox(width: Spaces.small),
                    Expanded(
                      child: SelectableText(
                        incoming!.from,
                        style: context.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spaces.medium),
                Text(
                  loc.transfers,
                  style: context.titleSmall
                      ?.copyWith(color: context.moreColors.mutedColor),
                ),
                const Divider(),
                Builder(
                  builder: (BuildContext context) {
                    var transfers = incoming!.transfers;

                    if (hideZeroTransfer) {
                      transfers = transfers.skipWhile((value) {
                        return value.amount == 0;
                      }).toList(growable: false);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: transfers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final transfer = transfers[index];
                        final isXelis = transfer.asset == sdk.xelisAsset;
                        final xelisPath = AppResources.xelisAsset.imagePath!;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Spaces.medium,
                                Spaces.small, Spaces.medium, Spaces.small),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: Spaces.extraSmall),
                                      child: Text(loc.asset,
                                          style: context.labelMedium?.copyWith(
                                              color: context
                                                  .moreColors.mutedColor)),
                                    ),
                                    isXelis
                                        ? Row(
                                            children: [
                                              Logo(
                                                imagePath: xelisPath,
                                              ),
                                              const SizedBox(
                                                  width: Spaces.small),
                                              Text(
                                                  AppResources.xelisAsset.name),
                                            ],
                                          )
                                        : Text(truncateText(transfer.asset)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: Spaces.extraSmall),
                                      child: Text(loc.amount,
                                          style: context.labelMedium?.copyWith(
                                              color: context
                                                  .moreColors.mutedColor)),
                                    ),
                                    SelectableText(isXelis
                                        ? '+${formatXelis(transfer.amount)}'
                                        : '${transfer.amount}'),
                                  ],
                                ),
                                if (!hideExtraData) ...[
                                  const SizedBox(height: Spaces.medium),
                                  Text(loc.extra_data,
                                      style: context.labelMedium?.copyWith(
                                          color:
                                              context.moreColors.mutedColor)),
                                  SelectableText(transfer.extraData.toString()),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError('${loc.launch_url_error} $url');
    }
  }
}
