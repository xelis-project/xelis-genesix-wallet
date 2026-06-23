import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/last_transactions_provider.dart';
import 'package:genesix/features/wallet/application/pending_transactions_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
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
  final Set<String> _animatedHashes = {};

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((value) => value.network),
    );
    final knownAssets = ref.watch(
      walletRuntimeProvider.select((value) => value.knownAssets),
    );

    final lastTransactionsAsync = ref.watch(lastTransactionsProvider);
    final pendingTransactionsAsync = ref.watch(pendingTransactionsProvider);
    final addressBookAsync = ref.watch(addressBookProvider);

    final content = addressBookAsync.when(
      data: (addressBook) => pendingTransactionsAsync.when(
        data: (pendingTransactions) => lastTransactionsAsync.when(
          data: (lastTransactions) => _buildTransactionList(
            loc: loc,
            network: network,
            knownAssets: knownAssets,
            addressBook: addressBook,
            pendingTransactions: pendingTransactions,
            lastTransactions: lastTransactions,
          ),
          loading: _buildLoading,
          error: _buildError,
        ),
        loading: _buildLoading,
        error: _buildError,
      ),
      loading: _buildLoading,
      error: _buildError,
    );

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.last_transactions,
                  style: context.theme.typography.display.xl.copyWith(
                    color: context.theme.colors.primary,
                  ),
                ),
              ),
              FTooltip(
                tipBuilder: (context, controller) => Text('refresh'),
                child: FButton.icon(
                  child: const Icon(FLucideIcons.refreshCcw),
                  onPress: () {
                    ref.invalidate(pendingTransactionsProvider);
                    ref.invalidate(lastTransactionsProvider);
                  },
                ),
              ),
            ],
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildTransactionList({
    required AppLocalizations loc,
    required rust.Network network,
    required LinkedHashMap<String, AssetData> knownAssets,
    required Map<String, ContactDetails> addressBook,
    required List<TransactionPending> pendingTransactions,
    required List<TransactionEntry> lastTransactions,
  }) {
    if (pendingTransactions.isEmpty && lastTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Spaces.small),
        child: Text(
          loc.no_recent_transactions,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      );
    }

    if (_animatedHashes.isEmpty) {
      for (final tx in pendingTransactions) {
        _animatedHashes.add(_pendingAnimationKey(tx.hash));
      }
      for (final tx in lastTransactions) {
        _animatedHashes.add(tx.hash);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FItemGroup.builder(
          count: pendingTransactions.length + lastTransactions.length,
          itemBuilder: (context, index) {
            if (index < pendingTransactions.length) {
              return _buildPendingTransactionItem(
                loc: loc,
                network: network,
                knownAssets: knownAssets,
                addressBook: addressBook,
                tx: pendingTransactions[index],
              );
            }

            final tx = lastTransactions[index - pendingTransactions.length];
            return _buildConfirmedTransactionItem(
              loc: loc,
              network: network,
              knownAssets: knownAssets,
              addressBook: addressBook,
              tx: tx,
            );
          },
        ),
        const SizedBox(height: Spaces.small),
        FButton(
          variant: .ghost,
          onPress: () => context.go(AuthAppScreen.history.toPath),
          suffix: Icon(FLucideIcons.arrowRight),
          child: Text(loc.view_all),
        ),
      ],
    );
  }

  Widget _buildPendingTransactionItem({
    required AppLocalizations loc,
    required rust.Network network,
    required LinkedHashMap<String, AssetData> knownAssets,
    required Map<String, ContactDetails> addressBook,
    required TransactionPending tx,
  }) {
    final info = parseTxInfo(
      loc,
      network,
      tx.txEntryType,
      knownAssets,
      addressBook,
    );
    final animationKey = _pendingAnimationKey(tx.hash);
    final isNew = !_animatedHashes.contains(animationKey);
    if (isNew) {
      _markAnimatedAfterBuild(animationKey);
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween(begin: isNew ? 0.0 : 1.0, end: 1.0),
      duration: Duration(milliseconds: isNew ? 300 : 0),
      curve: Curves.easeOut,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: FItem(
        prefix: Icon(info.icon, color: info.color),
        title: Text(info.label, style: context.theme.typography.body.sm),
        subtitle: Text(
          _transactionSubtitle(info) ??
              '${loc.hash}: ${truncateText(tx.hash, maxLength: 16)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        details: Text(
          tx.timestamp == null ? loc.pending : timeAgo(loc, tx.timestamp!),
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        suffix: FBadge(variant: .secondary, child: Text(loc.pending)),
      ),
    );
  }

  Widget _buildConfirmedTransactionItem({
    required AppLocalizations loc,
    required rust.Network network,
    required LinkedHashMap<String, AssetData> knownAssets,
    required Map<String, ContactDetails> addressBook,
    required TransactionEntry tx,
  }) {
    final info = parseTxInfo(
      loc,
      network,
      tx.txEntryType,
      knownAssets,
      addressBook,
    );

    final isNew = !_animatedHashes.contains(tx.hash);
    if (isNew) {
      _markAnimatedAfterBuild(tx.hash);
    }
    final subtitle = _transactionSubtitle(info);

    return TweenAnimationBuilder<double>(
      key: ValueKey(tx.hash),
      tween: Tween(begin: isNew ? 0.0 : 1.0, end: 1.0),
      duration: Duration(milliseconds: isNew ? 300 : 0),
      curve: Curves.easeOut,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: FItem(
        prefix: Icon(info.icon, color: info.color),
        title: Text(info.label, style: context.theme.typography.body.sm),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              )
            : null,
        details: tx.timestamp == null
            ? null
            : Text(
                timeAgo(loc, tx.timestamp!),
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
        suffix: TransactionInfoSuffix(info: info),
        onPress: () => _showTransactionEntry(tx),
      ),
    );
  }

  Widget _buildLoading() => Center(child: FCircularProgress());

  Widget _buildError(Object err, StackTrace stack) {
    final loc = ref.read(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: Spaces.small),
      child: Text(
        loc.oups,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.destructive,
        ),
      ),
    );
  }

  String? _transactionSubtitle(TransactionDisplayInfo info) {
    final parts = [
      if (info.subtitle != null) info.subtitle!,
      if (info.details != null) info.details!,
    ];
    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }
    return null;
  }

  String _pendingAnimationKey(String hash) => 'pending:$hash';

  void _markAnimatedAfterBuild(String hash) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _animatedHashes.add(hash);
        });
      }
    });
  }

  void _showTransactionEntry(TransactionEntry transactionEntry) {
    context.push(
      AuthAppScreen.transactionEntry.toPath,
      extra: transactionEntry,
    );
  }
}
