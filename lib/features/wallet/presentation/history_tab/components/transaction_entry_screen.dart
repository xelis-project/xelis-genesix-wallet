import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';

class TransactionEntryScreenExtra {
  final TransactionEntry transactionEntry;

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

  CoinbaseEntry? coinbase;
  OutgoingEntry? outgoing;
  BurnEntry? burn;
  IncomingEntry? incoming;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final hideZeroTransfer =
        ref.watch(settingsProvider.select((value) => value.hideZeroTransfer));
    final hideExtraData =
        ref.watch(settingsProvider.select((value) => value.hideExtraData));
    final extra = widget.routerState.extra as TransactionEntryScreenExtra;
    final transactionEntry = extra.transactionEntry;
    final entryType = transactionEntry.txEntryType;

    var displayTopoheight = NumberFormat().format(transactionEntry.topoHeight);

    switch (entryType) {
      case CoinbaseEntry():
        entryTypeName = loc.coinbase;
        coinbase = entryType;
        icon = const Icon(Icons.square_rounded);
      case BurnEntry():
        entryTypeName = loc.burn;
        burn = entryType;
        icon = const Icon(Icons.fireplace_rounded);
      case IncomingEntry():
        entryTypeName = loc.incoming;
        incoming = entryType;
        icon = const Icon(Icons.arrow_downward);
      case OutgoingEntry():
        entryTypeName = loc.outgoing;
        outgoing = entryType;
        icon = const Icon(Icons.arrow_upward);
    }

    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GenericAppBar(title: loc.transaction_entry),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spaces.large, 0, Spaces.large, Spaces.large),
          children: [
            Text(loc.type, style: context.headlineSmall),
            const SizedBox(height: Spaces.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SelectableText(
                  entryTypeName,
                  style: context.bodyLarge!
                      .copyWith(color: context.moreColors.mutedColor),
                ),
                const SizedBox(width: Spaces.medium),
                icon,
              ],
            ),
            const SizedBox(height: Spaces.medium),
            Text(loc.topoheight, style: context.headlineSmall),
            const SizedBox(height: Spaces.small),
            SelectableText(
              displayTopoheight,
              style: context.bodyLarge!
                  .copyWith(color: context.moreColors.mutedColor),
            ),
            const SizedBox(height: Spaces.medium),
            Text(loc.hash, style: context.headlineSmall),
            const SizedBox(height: Spaces.small),
            SelectableText(
              transactionEntry.hash,
              style: context.bodyLarge!
                  .copyWith(color: context.moreColors.mutedColor),
            ),

            // COINBASE
            if (entryType is CoinbaseEntry)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spaces.medium),
                  Text(loc.amount, style: context.headlineSmall),
                  const SizedBox(height: Spaces.small),
                  SelectableText(
                    '+${formatXelis(coinbase!.reward)} XEL', // hmm coinbase could return other asset than XELIS
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor),
                  ),
                ],
              ),

            // BURN
            if (entryType is BurnEntry)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spaces.medium),
                  Text(loc.burn, style: context.headlineSmall),
                  const SizedBox(height: Spaces.small),
                  SelectableText(
                    '-${formatXelis(burn!.amount)} XEL',
                    style: context.bodyLarge!
                        .copyWith(color: context.moreColors.mutedColor),
                  ),
                ],
              ),

            // OUTGOING
            if (entryType is OutgoingEntry) ...[
              const SizedBox(height: Spaces.medium),
              Text(loc.fee, style: context.headlineSmall),
              const SizedBox(height: Spaces.small),
              SelectableText(
                '${formatXelis(outgoing!.fee)} XEL',
                style: context.bodyLarge!
                    .copyWith(color: context.moreColors.mutedColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spaces.medium),
                  Text(
                    loc.transfers,
                    style: context.headlineSmall,
                  ),
                  const Divider(),
                  Builder(
                    builder: (BuildContext context) {
                      var transfers = outgoing!.transfers;

                      if (hideZeroTransfer) {
                        transfers = transfers.skipWhile((value) {
                          return value.amount == 0 && value.extraData == null;
                        }).toList(growable: false);
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: transfers.length,
                        itemBuilder: (BuildContext context, int index) {
                          final transfer = transfers[index];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(Spaces.medium,
                                  Spaces.medium, Spaces.medium, Spaces.medium),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      RandomAvatar(transfer.destination,
                                          width: 35, height: 35),
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
                                              style: context.labelLarge),
                                          SelectableText(
                                              transfer.asset == xelisAsset
                                                  ? 'XELIS'
                                                  : transfer.asset),
                                        ],
                                      ),
                                      const SizedBox(width: Spaces.medium),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(loc.amount,
                                              /* transfer.asset == xelisAsset
                                            ? loc.amount.capitalize
                                            : '${loc.amount.capitalize} (${loc.atomic_units})',*/
                                              style: context.labelLarge),
                                          SelectableText(transfer.asset ==
                                                  xelisAsset
                                              ? '-${formatXelis(transfer.amount)} XEL'
                                              : '${transfer.amount}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (transfer.extraData != null &&
                                      !hideExtraData) ...[
                                    const SizedBox(height: Spaces.medium),
                                    Text(loc.extra_data,
                                        style: context.labelLarge),
                                    SelectableText(
                                        transfer.extraData.toString()),
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
            if (entryType is IncomingEntry)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spaces.medium),
                  Text(loc.from, style: context.headlineSmall),
                  const SizedBox(height: Spaces.small),
                  Row(
                    children: [
                      RandomAvatar(incoming!.from, width: 35, height: 35),
                      const SizedBox(width: Spaces.small),
                      Expanded(
                        child: SelectableText(
                          incoming!.from,
                          style: context.bodyLarge!
                              .copyWith(color: context.moreColors.mutedColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spaces.medium),
                  Text(
                    loc.transfers,
                    style: context.headlineSmall,
                  ),
                  const Divider(),
                  Builder(
                    builder: (BuildContext context) {
                      var transfers = incoming!.transfers;

                      if (hideZeroTransfer) {
                        transfers = transfers.skipWhile((value) {
                          return value.amount == 0 && value.extraData == null;
                        }).toList(growable: false);
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: transfers.length,
                        itemBuilder: (BuildContext context, int index) {
                          final transfer = transfers[index];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(Spaces.medium,
                                  Spaces.small, Spaces.medium, Spaces.small),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.asset,
                                          style: context.labelLarge),
                                      SelectableText(
                                          transfer.asset == xelisAsset
                                              ? 'XELIS'
                                              : transfer.asset),
                                    ],
                                  ),
                                  const SizedBox(width: Spaces.medium),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.amount,
                                          /*transfer.asset == xelisAsset
                                          ? loc.amount.capitalize
                                          : '${loc.amount.capitalize} (${loc.atomic_units})',*/
                                          style: context.labelLarge),
                                      SelectableText(transfer.asset ==
                                              xelisAsset
                                          ? '+${formatXelis(transfer.amount)} XEL'
                                          : '${transfer.amount}'),
                                    ],
                                  ),
                                  if (transfer.extraData != null &&
                                      !hideExtraData) ...[
                                    const SizedBox(height: Spaces.medium),
                                    Text(loc.extra_data,
                                        style: context.labelLarge),
                                    SelectableText(
                                        transfer.extraData.toString()),
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
      ),
    );
  }
}
