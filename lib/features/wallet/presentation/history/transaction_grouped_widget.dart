import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class TransactionGroupedWidget extends ConsumerStatefulWidget {
  const TransactionGroupedWidget(
    this.transactionGroup,
    this.addressBook, {
    super.key,
  });

  final MapEntry<DateTime, List<TransactionEntry>> transactionGroup;
  final Map<String, ContactDetails> addressBook;

  @override
  ConsumerState createState() => _TransactionGroupedWidgetState();
}

class _TransactionGroupedWidgetState
    extends ConsumerState<TransactionGroupedWidget> {
  final Set<String> _animatedHashes = {};

  @override
  void initState() {
    super.initState();
    // Mark all initial transactions as already animated
    for (final tx in widget.transactionGroup.value) {
      _animatedHashes.add(tx.hash);
    }
  }

  @override
  void didUpdateWidget(TransactionGroupedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't auto-add new transactions here - let them animate
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final locale = ref.watch(settingsProvider.select((state) => state.locale));
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );

    final transactions = widget.transactionGroup.value;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: FDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
              child: Text(
                formatDateNicely(widget.transactionGroup.key, locale),
              ),
            ),
            Expanded(child: FDivider()),
          ],
        ),
        FItemGroup.builder(
          count: transactions.length,
          itemBuilder: (BuildContext context, int index) {
            final tx = transactions[index];
            final info = parseTxInfo(
              loc,
              network,
              tx.txEntryType,
              knownAssets,
              widget.addressBook,
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
                prefix: Icon(info.icon, color: info.color, size: 18),
                title: Text(info.label, style: context.theme.typography.sm),
                subtitle: info.subtitle != null
                    ? Text(
                        info.subtitle!,
                        style: context.theme.typography.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      )
                    : null,
                details: info.details != null
                    ? Text(
                        info.details!,
                        style: context.theme.typography.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      )
                    : null,
                suffix: Icon(FIcons.chevronRight),
                onPress: () => _showTransactionEntry(tx),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showTransactionEntry(TransactionEntry transactionEntry) {
    context.push(
      AuthAppScreen.transactionEntry.toPath,
      extra: transactionEntry,
    );
  }
}
