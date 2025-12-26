import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/history/base_transaction_entry_card.dart';
import 'package:genesix/features/wallet/presentation/history/burn_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/deploy_contract_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/invoke_contract_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/multisig_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/outgoing_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/incoming_entry_content.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/features/wallet/presentation/history/coinbase_entry_content.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  ConsumerState createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState
    extends ConsumerState<TransactionEntryScreen> {
  final _controller = ScrollController();

  late String entryTypeName;

  late Color color;

  late Widget transactionTypeContent;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final locale = ref.watch(settingsProvider.select((state) => state.locale));
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );

    final transactionEntry =
        context.goRouterState.extra as sdk.TransactionEntry;
    final entryType = transactionEntry.txEntryType;

    int? nonce;
    String hashPath = 'tx/';
    switch (entryType) {
      case sdk.CoinbaseEntry():
        entryTypeName = loc.coinbase;
        color = Colors.amber;
        hashPath = 'block/';
        transactionTypeContent = CoinbaseEntryContent(entryType);
      case sdk.BurnEntry():
        entryTypeName = loc.burn;
        color = Colors.orange;
        nonce = entryType.nonce;
        transactionTypeContent = BurnEntryContent(entryType);
      case sdk.IncomingEntry():
        entryTypeName = loc.incoming;
        color = Colors.greenAccent.shade400;
        transactionTypeContent = IncomingEntryContent(entryType);
      case sdk.OutgoingEntry():
        entryTypeName = loc.outgoing;
        color = Colors.redAccent.shade200;
        nonce = entryType.nonce;
        transactionTypeContent = OutgoingEntryContent(entryType);
      case sdk.MultisigEntry():
        entryTypeName = loc.multisig;
        color = Colors.blueAccent.shade200;
        nonce = entryType.nonce;
        transactionTypeContent = MultisigEntryContent(entryType);
      case sdk.InvokeContractEntry():
        entryTypeName = 'Contract Invocation';
        color = Colors.deepPurple;
        nonce = entryType.nonce;
        transactionTypeContent = InvokeContractEntryContent(entryType);
      case sdk.DeployContractEntry():
        entryTypeName = 'Contract Deployment';
        color = Colors.teal;
        nonce = entryType.nonce;
        transactionTypeContent = DeployContractEntryContent(entryType);
    }

    Uri url;
    switch (network) {
      case Network.mainnet:
        url = Uri.parse(
          '${AppResources.explorerMainnetUrl}$hashPath${transactionEntry.hash}',
        );
      case Network.testnet || Network.devnet || Network.stagenet:
        url = Uri.parse(
          '${AppResources.explorerTestnetUrl}$hashPath${transactionEntry.hash}',
        );
    }

    final displayTimestamp = transactionEntry.timestamp != null
        ? formatPrettyTimestamp(transactionEntry.timestamp!, locale)
        : loc.not_available;

    final displayTopoheight = NumberFormat().format(
      transactionEntry.topoheight,
    );

    return FScaffold(
      header: FHeader.nested(
        title: Text(loc.transaction),
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction(
              icon: const Icon(FIcons.arrowLeft),
              onPress: () => context.pop(),
            ),
          ),
        ],
      ),
      child: BodyLayoutBuilder(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spaces.small),
          child: FadedScroll(
            controller: _controller,
            fadeFraction: 0.08,
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                spacing: Spaces.medium,
                children: [
                  BaseTransactionEntryCard(
                    transactionEntry: transactionEntry,
                    type: entryTypeName,
                    color: color,
                    timestamp: displayTimestamp,
                    topoheight: displayTopoheight,
                    url: url,
                    nonce: nonce,
                  ),
                  transactionTypeContent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
