import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/burn_entry_widget.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/coinbase_entry_widget.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/incoming_entry_widget.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/outgoing_entry_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class TabContentWidget extends ConsumerWidget {
  const TabContentWidget(this.entries, {super.key});

  final List<TransactionEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    if (entries.isNotEmpty) {
      entries.sort((a, b) => b.topoHeight.compareTo(a.topoHeight));
      return ListView.builder(
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int index) {
          final entry = entries[index];
          return switch (entry.txEntryType) {
            CoinbaseEntry() => CoinbaseEntryWidget(transactionEntry: entry),
            BurnEntry() => BurnEntryWidget(transactionEntry: entry),
            IncomingEntry() => IncomingEntryWidget(transactionEntry: entry),
            OutgoingEntry() => OutgoingEntryWidget(transactionEntry: entry),
          };
        },
      );
    } else {
      return Center(
        child: Text(
          loc.no_data,
          style: context.headlineSmall,
        ),
      );
    }
  }
}
