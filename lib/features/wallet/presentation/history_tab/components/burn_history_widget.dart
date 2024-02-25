import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/history_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/tab_content_widget.dart';

class BurnHistoryWidget extends ConsumerWidget {
  const BurnHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burnEntriesSet =
        ref.watch(historyProvider.select((value) => value.value?.burnEntries));
    final burnEntriesList = burnEntriesSet?.toList() ?? [];
    return Tab(child: TabContentWidget(burnEntriesList));
  }
}
