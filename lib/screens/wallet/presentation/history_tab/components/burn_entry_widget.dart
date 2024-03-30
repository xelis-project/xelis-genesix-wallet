import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/coinbase_details_dialog.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';

class BurnEntryWidget extends ConsumerStatefulWidget {
  const BurnEntryWidget({super.key, required this.transactionEntry});

  final TransactionEntry transactionEntry;

  @override
  ConsumerState<BurnEntryWidget> createState() => _BurnEntryWidgetState();
}

class _BurnEntryWidgetState extends ConsumerState<BurnEntryWidget> {
  void _showDetails(BuildContext context, TransactionEntry transactionEntry) {
    showDialog<void>(
      context: context,
      builder: (_) => CoinbaseDetailsDialog(transactionEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final entryType = widget.transactionEntry.txEntryType as BurnEntry;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spaces.medium, Spaces.small, Spaces.medium, Spaces.small),
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
                const SizedBox(width: Spaces.small),
                Text(
                  '${widget.transactionEntry.topoHeight}',
                  style: context.bodyLarge,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entryType.asset == xelisAsset
                      ? loc.amount.capitalize
                      : '${loc.amount.capitalize} (${loc.atomic_units})',
                  style: context.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: Spaces.small),
                SelectableText(
                  entryType.asset == xelisAsset
                      ? '- ${formatXelis(entryType.amount)} XEL'
                      : '- ${entryType.amount}',
                  style: context.bodyLarge,
                ),
              ],
            ),
            IconButton(
                onPressed: () {
                  _showDetails(context, widget.transactionEntry);
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
