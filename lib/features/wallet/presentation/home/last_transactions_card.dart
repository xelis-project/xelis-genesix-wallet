import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/last_transactions_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';

// import 'package:genesix/shared/widgets/components/custom_skeletonizer.dart';
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

    final lastTransactions = ref.watch(lastTransactionsProvider).valueOrNull;

    Widget content;
    if (lastTransactions != null) {
      if (lastTransactions.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: Text(
            'No transactions yet.',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        );
      } else {
        content = FItemGroup.builder(
          count: lastTransactions.length,
          itemBuilder: (context, index) {
            final tx = lastTransactions[index];
            final info = parseTxInfo(
              loc,
              network,
              tx.txEntryType,
              knownAssets,
              const {}, // No address book in this context
            );

            return FItem(
              prefix: Icon(info.icon, color: info.color),
              title: Text(info.label, style: context.theme.typography.sm),
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
              onPress: () => _showTransactionEntry(tx),
            );
          },
        );
      }
    } else {
      // content = CustomSkeletonizer(
      //   child: Column(
      //     children: List.generate(
      //       5,
      //       (_) => Row(
      //         children: [
      //           Icon(
      //             FIcons.user,
      //             color: context.theme.colors.mutedForeground,
      //           ),
      //           Column(
      //             children: [
      //               Text(
      //                 'Dummy title',
      //                 style: context.theme.typography.sm.copyWith(
      //                   color: context.theme.colors.mutedForeground,
      //                 ),
      //               ),
      //               Text(
      //                 'Dummy subtitle',
      //                 style: context.theme.typography.xs.copyWith(
      //                   color: context.theme.colors.mutedForeground,
      //                 ),
      //               )
      //             ],
      //           ),
      //           Spacer(),
      //           Text(
      //             'Dummy details',
      //             style: context.theme.typography.xs.copyWith(
      //               color: context.theme.colors.mutedForeground,
      //             ),
      //           )
      //         ],
      //       ),
      //     ).toList(growable: false),
      //   ),
      // );
      content = SizedBox(
        height: 200,
        child: Center(child: FProgress.circularIcon()),
      );
    }

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
          content,
          if (lastTransactions != null && lastTransactions.isNotEmpty) ...[
            const SizedBox(height: Spaces.small),
            FButton(
              style: FButtonStyle.ghost(),
              onPress: () => context.go(AuthAppScreen.history.toPath),
              suffix: Icon(FIcons.arrowRight),
              child: Text('See All'),
            ),
          ],
        ],
      ),
    );
  }

  void _showTransactionEntry(TransactionEntry transactionEntry) {
    context.push(
      AuthAppScreen.transactionEntry.toPath,
      extra: transactionEntry,
    );
  }
}
