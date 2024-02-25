import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class CoinbaseEntryWidget extends ConsumerStatefulWidget {
  const CoinbaseEntryWidget({super.key, required this.transactionEntry});

  final TransactionEntry transactionEntry;

  @override
  ConsumerState<CoinbaseEntryWidget> createState() =>
      _CoinbaseEntryWidgetState();
}

class _CoinbaseEntryWidgetState extends ConsumerState<CoinbaseEntryWidget> {
  late final Future<String> formattedReward;

  @override
  void initState() {
    super.initState();
    formattedReward = ref.read(walletStateProvider.notifier).formatCoin(
        (widget.transactionEntry.txEntryType as CoinbaseEntry).reward);
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
                  loc.reward,
                  style: context.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: 8),
                FutureBuilder(
                  future: formattedReward,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
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
                      'coinbase entry at topo: ${widget.transactionEntry.topoHeight}');
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
