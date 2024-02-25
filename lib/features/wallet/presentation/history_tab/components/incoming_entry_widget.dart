import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';

class IncomingEntryWidget extends ConsumerStatefulWidget {
  const IncomingEntryWidget({super.key, required this.transactionEntry});

  final TransactionEntry transactionEntry;

  @override
  ConsumerState<IncomingEntryWidget> createState() =>
      _IncomingEntryWidgetState();
}

class _IncomingEntryWidgetState extends ConsumerState<IncomingEntryWidget> {
  late final Future<String> formattedAmount;
  bool _multiTx = false;

  @override
  void initState() {
    super.initState();
    if ((widget.transactionEntry.txEntryType as IncomingEntry)
            .transfers
            .length >
        1) {
      _multiTx = true;
    } else if ((widget.transactionEntry.txEntryType as IncomingEntry)
            .transfers
            .length ==
        1) {
      final transfer = (widget.transactionEntry.txEntryType as IncomingEntry)
          .transfers
          .first;
      formattedAmount =
          ref.read(walletStateProvider.notifier).formatCoin(transfer.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Card(
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
                  '${widget.transactionEntry.topoHeight}',
                  style: context.bodyLarge,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.amount.capitalize,
                  style: context.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: 8),
                _multiTx
                    // TODO
                    ? Text('multi Tx', style: context.bodyLarge)
                    : FutureBuilder(
                        future: formattedAmount,
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '+ ${snapshot.data ?? '...'} XEL',
                              style: context.bodyLarge,
                            );
                          } else {
                            return Text(
                              '...',
                              style: context.bodyLarge,
                            );
                          }
                        },
                      ),
              ],
            ),
            IconButton(
                onPressed: () {
                  // TODO
                  debugPrint(
                      'incoming entry at topo: ${widget.transactionEntry.topoHeight}');
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
