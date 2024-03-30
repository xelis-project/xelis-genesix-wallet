import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/history_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/history_tab/components/tab_content_widget.dart';

class CoinbaseHistoryWidget extends ConsumerWidget {
  const CoinbaseHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinbaseEntriesSet = ref
        .watch(historyProvider.select((value) => value.value?.coinbaseEntries));
    final coinbaseEntriesList = coinbaseEntriesSet?.toList() ?? [];
    return Tab(child: TabContentWidget(coinbaseEntriesList));
  }
}
