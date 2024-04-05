import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/outgoing_details_dialog.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';

class OutgoingEntryWidget extends ConsumerStatefulWidget {
  const OutgoingEntryWidget({super.key, required this.transactionEntry});

  final TransactionEntry transactionEntry;

  @override
  ConsumerState<OutgoingEntryWidget> createState() =>
      _OutgoingEntryWidgetState();
}

class _OutgoingEntryWidgetState extends ConsumerState<OutgoingEntryWidget> {
  late final OutgoingEntry _entryType;

  TransferOutEntry? _transferEntry;

  @override
  void initState() {
    super.initState();
    _entryType = widget.transactionEntry.txEntryType as OutgoingEntry;
    if (_entryType.transfers.length == 1) {
      _transferEntry = _entryType.transfers.first;
    }
  }

  void _showDetails(BuildContext context, TransactionEntry transactionEntry) {
    showDialog<void>(
      context: context,
      builder: (_) => OutgoingDetailsDialog(transactionEntry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
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
                  _transferEntry == null || _transferEntry?.asset == xelisAsset
                      ? loc.amount.capitalize
                      : '${loc.amount.capitalize} (${loc.atomic_units})',
                  style: context.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: Spaces.small),
                _transferEntry == null
                    ? Text('multi Tx', style: context.bodyLarge)
                    : SelectableText(
                        _transferEntry!.asset == xelisAsset
                            ? '- ${formatXelis(_transferEntry!.amount)} XEL'
                            : '- ${_transferEntry!.amount}',
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
