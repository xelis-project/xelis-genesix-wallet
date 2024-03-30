import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/history_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/tab_content_widget.dart';

class IncomingHistoryWidget extends ConsumerWidget {
  const IncomingHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingEntriesSet = ref
        .watch(historyProvider.select((value) => value.value?.incomingEntries));
    final incomingEntriesList = incomingEntriesSet?.toList() ?? [];
    return Tab(child: TabContentWidget(incomingEntriesList));
  }
}
