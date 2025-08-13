import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/last_transactions_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/transaction_view_utils.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';

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
                return Column(
                  children: [
                    const SizedBox(height: Spaces.small),
                    Text(
                      'No transactions yet.',
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                );
              }

              final txs = snapshot.data!;

              return FItemGroup.builder(
                count: txs.length,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  final info = parseTxInfo(
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
}
