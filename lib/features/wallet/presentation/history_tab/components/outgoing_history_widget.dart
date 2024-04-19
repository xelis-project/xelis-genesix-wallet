import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/history_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/tab_content_widget.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class OutgoingHistoryWidget extends ConsumerWidget {
  const OutgoingHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideZeroTransfer =
        ref.watch(settingsProvider.select((value) => value.hideZeroTransfer));
    final outgoingEntriesSet = ref
        .watch(historyProvider.select((value) => value.value?.outgoingEntries));
    var outgoingEntries = outgoingEntriesSet?.toList() ?? [];

    if (hideZeroTransfer) {
      outgoingEntries = outgoingEntries.skipWhile((entry) {
        var zeroTransfer = true;
        for (final transfer in (entry.txEntryType as OutgoingEntry).transfers) {
          if (transfer.amount != 0) {
            zeroTransfer = false;
            break;
          }
        }
        return zeroTransfer;
      }).toList(growable: false);
    }

    return Tab(child: TabContentWidget(outgoingEntries));
  }
}
