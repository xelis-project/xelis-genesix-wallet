import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/burn_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/coinbase_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/deploy_contract_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/incoming_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/invoke_contract_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/multisig_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/outgoing_entry_content.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';

class TransactionEntryScreenExtra {
  final sdk.TransactionEntry transactionEntry;

  TransactionEntryScreenExtra(this.transactionEntry);
}

class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({required this.routerState, super.key});

  final GoRouterState routerState;

  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState
    extends ConsumerState<TransactionEntryScreen> {
  late String entryTypeName;
  late Icon icon;
  sdk.CoinbaseEntry? coinbase;
  sdk.OutgoingEntry? outgoing;
  sdk.BurnEntry? burn;
  sdk.IncomingEntry? incoming;
  sdk.MultisigEntry? multisig;
  sdk.InvokeContractEntry? invokeContract;
  sdk.DeployContractEntry? deployContract;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );

    final extra = widget.routerState.extra as TransactionEntryScreenExtra;
    final transactionEntry = extra.transactionEntry;
    final entryType = transactionEntry.txEntryType;

    Widget entryContent;
    String hashPath = 'txs/';
    switch (entryType) {
      case sdk.CoinbaseEntry():
        entryTypeName = loc.coinbase;
        coinbase = entryType;
        icon = Icon(Icons.square_rounded, color: context.colors.primary);
        hashPath = 'blocks/';
        entryContent = CoinbaseEntryContent(entryType);
      case sdk.BurnEntry():
        entryTypeName = loc.burn;
        burn = entryType;
        icon = Icon(
          Icons.local_fire_department_rounded,
          color: context.colors.primary,
        );
        entryContent = BurnEntryContent(entryType);
      case sdk.IncomingEntry():
        entryTypeName = loc.incoming;
        incoming = entryType;
        icon = Icon(Icons.call_received_rounded, color: context.colors.primary);
        entryContent = IncomingEntryContent(entryType);
      case sdk.OutgoingEntry():
        entryTypeName = loc.outgoing;
        outgoing = entryType;
        icon = Icon(Icons.call_made_rounded, color: context.colors.primary);
        entryContent = OutgoingEntryContent(entryType);
      case sdk.MultisigEntry():
        entryTypeName = loc.multisig;
        multisig = entryType;
        icon = Icon(Icons.call_made_rounded, color: context.colors.primary);
        entryContent = MultisigEntryContent(entryType);
      case sdk.InvokeContractEntry():
        entryTypeName = loc.invoked_contract;
        invokeContract = entryType;
        icon = Icon(Icons.call_made_rounded, color: context.colors.primary);
        entryContent = InvokeContractEntryContent(entryType);
      case sdk.DeployContractEntry():
        entryTypeName = loc.deployed_contract;
        deployContract = entryType;
        icon = Icon(Icons.call_made_rounded, color: context.colors.primary);
        entryContent = DeployContractEntryContent(entryType);
    }

    Uri url;
    switch (network) {
      case Network.mainnet:
        url = Uri.parse(
          '${AppResources.explorerMainnetUrl}$hashPath${transactionEntry.hash}',
        );
      default:
        url = Uri.parse(
          '${AppResources.explorerTestnetUrl}$hashPath${transactionEntry.hash}',
        );
    }

    var displayTopoheight = NumberFormat().format(transactionEntry.topoheight);

    return CustomScaffold(
      backgroundColor: Colors.transparent,
      appBar: GenericAppBar(title: loc.transaction),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spaces.large,
          Spaces.none,
          Spaces.large,
          Spaces.large,
        ),
        children: [
          Text(
            loc.type,
            style: context.labelLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          Row(
            children: [
              icon,
              const SizedBox(width: Spaces.small),
              SelectableText(entryTypeName, style: context.bodyLarge),
            ],
          ),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.topoheight,
            style: context.labelLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(displayTopoheight, style: context.bodyLarge),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.timestamp,
            style: context.labelLarge?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            transactionEntry.timestamp?.toString() ?? loc.not_available,
            style: context.bodyLarge,
          ),
          const SizedBox(height: Spaces.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.hash,
                style: context.labelLarge?.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              IconButton(
                onPressed: () => _launchUrl(url),
                icon: const Icon(Icons.link),
                tooltip: loc.explorer,
              ),
            ],
          ),
          SelectableText(transactionEntry.hash, style: context.bodyLarge),
          const SizedBox(height: Spaces.medium),
          entryContent,
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(snackBarQueueProvider.notifier)
          .showError('${loc.launch_url_error} $url');
    }
  }
}
