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
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class LastTransactionsCard extends ConsumerStatefulWidget {
  const LastTransactionsCard({super.key});

  @override
  ConsumerState<LastTransactionsCard> createState() =>
      _LastTransactionsCardState();
}

class _LastTransactionsCardState extends ConsumerState<LastTransactionsCard> {
  final Set<String> _animatedHashes = {};

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((value) => value.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );
    final isRescanning = ref.watch(
      walletStateProvider.select((s) => s.isRescanning),
    );

    final lastTransactions = ref.watch(lastTransactionsProvider).valueOrNull;

    Widget content;

    if (lastTransactions != null) {
      if (lastTransactions.isEmpty) {
        content = Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: Text(
            loc.no_recent_transactions,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        );
      } else {
        if (_animatedHashes.isEmpty) {
          for (final tx in lastTransactions) {
            _animatedHashes.add(tx.hash);
          }
        }
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FItemGroup.builder(
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

                final isNew = !_animatedHashes.contains(tx.hash);
                if (isNew) {
                  // Mark as animated after first build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _animatedHashes.add(tx.hash);
                      });
                    }
                  });
                }

                return TweenAnimationBuilder<double>(
                  key: ValueKey(tx.hash),
                  tween: Tween(begin: isNew ? 0.0 : 1.0, end: 1.0),
                  duration: Duration(milliseconds: isNew ? 300 : 0),
                  curve: Curves.easeOut,
                  builder: (context, opacity, child) =>
                      Opacity(opacity: opacity, child: child),
                  child: FItem(
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
                      timeAgo(loc, tx.timestamp!),
                      style: context.theme.typography.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    suffix: Icon(FIcons.chevronRight),
                    onPress: () => _showTransactionEntry(tx),
                  ),
                );
              },
            ),
            const SizedBox(height: Spaces.small),
            FButton(
              style: FButtonStyle.ghost(),
              onPress: () => context.go(AuthAppScreen.history.toPath),
              suffix: Icon(FIcons.arrowRight),
              child: Text(loc.view_all),
            ),
          ],
        );
      }
    } else {
      content = Padding(
        padding: const EdgeInsets.only(top: Spaces.small),
        child: Text(
          loc.oups,
          style: context.theme.typography.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
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
                  loc.last_transactions,
                  style: context.theme.typography.xl.copyWith(
                    color: context.theme.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          isRescanning ? Center(child: FCircularProgress()) : content,
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
