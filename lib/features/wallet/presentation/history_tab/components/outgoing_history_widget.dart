import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/history_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/tab_content_widget.dart';

class OutgoingHistoryWidget extends ConsumerWidget {
  const OutgoingHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoingEntriesSet = ref
        .watch(historyProvider.select((value) => value.value?.outgoingEntries));
    final outgoingEntriesList = outgoingEntriesSet?.toList() ?? [];
    return Tab(child: TabContentWidget(outgoingEntriesList));
  }
}
