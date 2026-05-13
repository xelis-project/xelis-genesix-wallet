import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
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
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/features/wallet/presentation/history/coinbase_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/incoming_contract_entry_content.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  ConsumerState createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen>
    with TickerProviderStateMixin {
  final _controller = ScrollController();
  late final AnimationController _animController;
  late final Animation<double> _fadeBase;
  late final Animation<Offset> _slideBase;
  late final Animation<double> _fadeContent;
  late final Animation<Offset> _slideContent;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeBase = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideBase = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fadeBase);

    _fadeContent = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _slideContent = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fadeContent);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final locale = ref.watch(settingsProvider.select((state) => state.locale));
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );

    final transactionEntry =
        context.goRouterState.extra as sdk.TransactionEntry;
    final entryType = transactionEntry.txEntryType;

    // Use parseTxInfo to get icon, color, label (avoids duplication)
    final txInfo = parseTxInfo(
      loc,
      network,
      entryType,
      knownAssets,
      const <String, ContactDetails>{},
    );

    // Entry-specific data that parseTxInfo doesn't handle
    int? nonce;
    String hashPath = 'tx/';
    late Widget transactionTypeContent;
    switch (entryType) {
      case sdk.CoinbaseEntry():
        hashPath = 'block/';
        transactionTypeContent = CoinbaseEntryContent(entryType);
      case sdk.BurnEntry():
        nonce = entryType.nonce;
        transactionTypeContent = BurnEntryContent(entryType);
      case sdk.IncomingEntry():
        transactionTypeContent = IncomingEntryContent(entryType);
      case sdk.OutgoingEntry():
        nonce = entryType.nonce;
        transactionTypeContent = OutgoingEntryContent(entryType);
      case sdk.MultisigEntry():
        nonce = entryType.nonce;
        transactionTypeContent = MultisigEntryContent(entryType);
      case sdk.InvokeContractEntry():
        nonce = entryType.nonce;
        transactionTypeContent = InvokeContractEntryContent(
          entryType,
          transactionEntry,
        );
      case sdk.DeployContractEntry():
        nonce = entryType.nonce;
        transactionTypeContent = DeployContractEntryContent(entryType);
      case sdk.IncomingContractEntry():
        transactionTypeContent = IncomingContractEntryContent(entryType);
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
      child: SafeArea(
        top: false,
        child: BodyLayoutBuilder(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spaces.small),
            child: FadedScroll(
              controller: _controller,
              fadeFraction: 0.08,
              child: SingleChildScrollView(
                controller: _controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Spaces.medium,
                  children: [
                    SlideTransition(
                      position: _slideBase,
                      child: FadeTransition(
                        opacity: _fadeBase,
                        child: BaseTransactionEntryCard(
                          transactionEntry: transactionEntry,
                          type: txInfo.label,
                          color: txInfo.color,
                          icon: txInfo.icon,
                          timestamp: displayTimestamp,
                          topoheight: displayTopoheight,
                          url: url,
                          nonce: nonce,
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _slideContent,
                      child: FadeTransition(
                        opacity: _fadeContent,
                        child: transactionTypeContent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
