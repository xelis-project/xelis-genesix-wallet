import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/coinbase_details_dialog.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';

class CoinbaseEntryWidget extends ConsumerWidget {
  const CoinbaseEntryWidget({super.key, required this.transactionEntry});

  final TransactionEntry transactionEntry;

  void _showDetails(BuildContext context, TransactionEntry transactionEntry) {
    showDialog<void>(
      context: context,
      builder: (_) => CoinbaseDetailsDialog(transactionEntry),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final entryType = transactionEntry.txEntryType as CoinbaseEntry;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.topoheight,
                  style: context.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  '${transactionEntry.topoHeight}',
                  style: context.bodyLarge,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.reward,
                  style: context.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: 8),
                SelectableText(
                  '+ ${formatXelis(entryType.reward)} XEL',
                  style: context.bodyLarge,
                ),
              ],
            ),
            IconButton(
                onPressed: () {
                  _showDetails(context, transactionEntry);
                },
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                )),
          ],
        ),
      ),
    );
  }
}
