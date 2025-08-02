import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/last_transactions_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class LastTransactionsCard extends ConsumerStatefulWidget {
  const LastTransactionsCard({super.key});

  @override
  ConsumerState<LastTransactionsCard> createState() =>
      _LastTransactionsCardState();
}

class _LastTransactionsCardState extends ConsumerState<LastTransactionsCard> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((value) => value.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );

    final transactions = ref.watch(lastTransactionsProvider.future);

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last Transactions',
                  style: context.theme.typography.xl.copyWith(
                    color: context.theme.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          FutureBuilder(
            future: transactions,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Column(
                  children: [
                    const SizedBox(height: Spaces.small),
                    Text(
                      'Error loading transactions.',
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  'No transactions yet.',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                );
              }

              final txs = snapshot.data!;

              return FItemGroup.builder(
                count: txs.length,
                // divider: FItemDivider.indented,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  final info = _parseTxInfo(
                    loc,
                    network,
                    tx.txEntryType,
                    knownAssets,
                  );

                  return FItem(
                    prefix: Icon(info.icon, color: info.color),
                    title: Text(
                      info.label,
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.primaryForeground,
                      ),
                    ),
                    subtitle: info.details != null
                        ? Text(
                            info.details!,
                            style: context.theme.typography.xs.copyWith(
                              color: context.theme.colors.mutedForeground,
                            ),
                          )
                        : null,
                    details: Text(
                      timeAgo(tx.timestamp!),
                      style: context.theme.typography.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    suffix: Icon(FIcons.chevronRight),
                    onPress: () {
                      // TODO: Handle transaction tap
                      // This could navigate to a transaction details page
                      print('Tapped on transaction: ${tx.hash}');
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: Spaces.small),
          FButton(
            style: FButtonStyle.ghost(),
            onPress: () => context.go(AuthAppScreen.history.toPath),
            suffix: Icon(FIcons.arrowRight),
            child: Text('See All'),
          ),
        ],
      ),
    );
  }

  _TransactionDisplayInfo _parseTxInfo(
    AppLocalizations loc,
    rust.Network network,
    TransactionEntryType type,
    LinkedHashMap<String, AssetData> knownAssets,
  ) {
    switch (type) {
      case CoinbaseEntry():
        return _TransactionDisplayInfo(
          icon: FIcons.star,
          color: Colors.amber,
          label: loc.coinbase,
          details: formatXelis(type.reward, network),
        );
      case BurnEntry():
        final asset = knownAssets[type.asset];
        return _TransactionDisplayInfo(
          icon: FIcons.flame,
          color: Colors.orange,
          label: loc.burn,
          details: asset != null
              ? formatCoin(type.amount, asset.decimals, asset.ticker)
              : 'Unknown Asset',
        );
      case IncomingEntry():
        String detailsMessage;
        if (type.transfers.length > 1) {
          detailsMessage = 'Multiple transfers received';
        } else if (type.transfers.isEmpty) {
          detailsMessage = 'No transfers found';
        } else {
          final transfer = type.transfers.first;
          final asset = knownAssets[transfer.asset];
          if (asset != null) {
            detailsMessage = formatCoin(
              transfer.amount,
              asset.decimals,
              asset.ticker,
            );
          } else {
            detailsMessage = 'Unknown Asset';
          }
        }
        return _TransactionDisplayInfo(
          icon: FIcons.arrowDownLeft,
          color: Colors.greenAccent.shade400,
          label: 'Received',
          details: detailsMessage,
        );
      case OutgoingEntry():
        String detailsMessage;
        if (type.transfers.length > 1) {
          detailsMessage = 'Multiple transfers sent';
        } else if (type.transfers.isEmpty) {
          detailsMessage = 'No transfers found';
        } else {
          final transfer = type.transfers.first;
          final asset = knownAssets[transfer.asset];
          if (asset != null) {
            detailsMessage = formatCoin(
              transfer.amount,
              asset.decimals,
              asset.ticker,
            );
          } else {
            detailsMessage = 'Unknown Asset';
          }
        }

        return _TransactionDisplayInfo(
          icon: FIcons.arrowUpRight,
          color: Colors.redAccent.shade200,
          label: 'Sent',
          details: detailsMessage,
        );
      case MultisigEntry():
        return _TransactionDisplayInfo(
          icon: FIcons.users,
          color: Colors.blueAccent.shade200,
          label: loc.multisig,
          details: type.participants.isEmpty ? 'Disabled' : 'Enabled',
        );
      case InvokeContractEntry():
        return _TransactionDisplayInfo(
          icon: FIcons.squareCode,
          color: Colors.deepPurple,
          label: 'Contract Invocation',
          details: truncateText(type.contract, maxLength: 16),
        );
      case DeployContractEntry():
        return _TransactionDisplayInfo(
          icon: FIcons.scrollText,
          color: Colors.teal,
          label: 'Contract Deployment',
          details: null,
        );
    }
  }
}

class _TransactionDisplayInfo {
  final IconData icon;
  final Color color;
  final String label;
  final String? details;

  _TransactionDisplayInfo({
    required this.icon,
    required this.color,
    required this.label,
    this.details,
  });
}
