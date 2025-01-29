import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_widget.dart';
import 'package:genesix/shared/theme/extensions.dart';

class TabContentWidget extends ConsumerWidget {
  const TabContentWidget(this.entries, {super.key});

  final List<TransactionEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    if (entries.isNotEmpty) {
      entries.sort((a, b) => b.topoheight.compareTo(a.topoheight));
      return ListView.builder(
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int index) {
          final entry = entries[index];
          return TransactionEntryWidget(transactionEntry: entry);
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
