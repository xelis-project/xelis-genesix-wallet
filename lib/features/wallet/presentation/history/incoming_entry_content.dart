import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transfer_entry_row.dart';
import 'package:genesix/features/wallet/presentation/history/transfers_view.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class IncomingEntryContent extends ConsumerWidget {
  const IncomingEntryContent(this.incomingEntry, {super.key});

  final IncomingEntry incomingEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    final hideZeroTransfer = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideZeroTransfer,
      ),
    );

    final rows = entryRowFromIncoming(
      incomingEntry,
      knownAssets,
      hideZeroTransfer,
    );

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: TransfersView.incoming(
          localizations: loc,
          rows: rows,
          fromAddress: incomingEntry.from,
        ),
      ),
    );
  }
}
