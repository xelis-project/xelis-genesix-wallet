import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';

class IncomingDetailsDialog extends ConsumerWidget {
  const IncomingDetailsDialog(this.transactionEntry, {super.key});

  final TransactionEntry transactionEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final entryType = transactionEntry.txEntryType as IncomingEntry;
    return AlertDialog(
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          loc.details,
          style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16.0),
            Column(
              children: [
                Text(
                  loc.topoheight,
                  style: context.labelMedium
                      ?.copyWith(color: context.colors.primary),
                ),
                SelectableText(transactionEntry.topoHeight.toString()),
              ],
            ),
            const SizedBox(height: 24.0),
            Column(
              children: [
                Text(
                  loc.tx_hash,
                  style: context.labelMedium
                      ?.copyWith(color: context.colors.primary),
                ),
                SelectableText(transactionEntry.hash)
              ],
            ),
            const SizedBox(height: 24.0),
            Column(
              children: [
                Text(
                  loc.sender,
                  style: context.labelMedium
                      ?.copyWith(color: context.colors.primary),
                ),
                SelectableText(entryType.from)
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  loc.transfers,
                  style: context.titleMedium,
                ),
              ],
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              itemCount: entryType.transfers.length,
              itemBuilder: (BuildContext context, int index) {
                final transfer = entryType.transfers[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              transfer.asset == xelisAsset
                                  ? loc.amount.capitalize
                                  : '${loc.amount.capitalize} (${loc.atomic_units})',
                              style: context.labelSmall
                                  ?.copyWith(color: context.colors.primary),
                            ),
                            SelectableText(transfer.asset == xelisAsset
                                ? formatXelis(transfer.amount)
                                : '${transfer.amount}'),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.asset,
                              style: context.labelSmall
                                  ?.copyWith(color: context.colors.primary),
                            ),
                            SelectableText(transfer.asset == xelisAsset
                                ? 'XELIS'
                                : transfer.asset),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.key,
                              style: context.labelSmall
                                  ?.copyWith(color: context.colors.primary),
                            ),
                            SelectableText(transfer.key),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(loc.ok_button),
        ),
      ],
    );
  }
}
