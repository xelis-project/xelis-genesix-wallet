import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/history/contract_asset_transfers.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class IncomingContractEntryContent extends ConsumerWidget {
  const IncomingContractEntryContent(this.incomingContractEntry, {super.key});

  final XelisWalletIncomingContractEntry incomingContractEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final knownAssets = ref.watch(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            ContractAssetTransfers(
              title: loc.transfers,
              transfers: incomingContractEntry.transfers,
              knownAssets: knownAssets,
              loc: loc,
            ),
          ],
        ),
      ),
    );
  }
}
