import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/transaction_entry_detail_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_entry_detail.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/features/wallet/presentation/history/base_transaction_entry_card.dart';
import 'package:genesix/features/wallet/presentation/history/blob_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/burn_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/deploy_contract_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/invoke_contract_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/multisig_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/outgoing_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/incoming_entry_content.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:genesix/features/wallet/presentation/history/coinbase_entry_content.dart';
import 'package:genesix/features/wallet/presentation/history/incoming_contract_entry_content.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({required this.routeEntry, super.key});

  final Object? routeEntry;

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
  late final TransactionEntryDetailRequest _request;

  @override
  void initState() {
    super.initState();
    _request = TransactionEntryDetail.fromRouteExtra(widget.routeEntry).request;
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
    final addressBookAsync = ref.watch(addressBookByAddressProvider);
    final Map<String, XelisAddressBookEntry> addressBook =
        switch (addressBookAsync) {
          AsyncData(:final value) => value,
          _ => const <String, XelisAddressBookEntry>{},
        };

    final detailAsync = ref.watch(transactionEntryDetailProvider(_request));
    if (detailAsync case AsyncLoading()) {
      return _buildStatusScaffold(
        context,
        loc,
        child: Center(child: FCircularProgress.loader()),
      );
    }
    if (detailAsync case AsyncError()) {
      return _buildStatusScaffold(
        context,
        loc,
        child: Row(
          spacing: Spaces.small,
          children: [
            Expanded(child: Text(loc.oups)),
            FButton(
              variant: .outline,
              onPress: () {
                ref.invalidate(transactionEntryDetailProvider(_request));
                ref.invalidate(transactionExactDestinationsProvider(_request));
              },
              child: Text(loc.refresh),
            ),
          ],
        ),
      );
    }

    final detail = detailAsync.requireValue;
    final exactDestinationsAsync = ref.watch(
      transactionExactDestinationsProvider(_request),
    );
    final exactDestinations = switch (exactDestinationsAsync) {
      AsyncData(:final value) => value,
      _ => const <XelisAddressBookEntry?>[],
    };
    final entryType = detail.entry;

    // Use parseTxInfo to get icon, color, label (avoids duplication)
    final txInfo = parseTxInfo(
      loc,
      network,
      entryType,
      knownAssets,
      addressBook,
      exactDestinations: exactDestinations,
    );

    // Entry-specific data that parseTxInfo doesn't handle
    BigInt? nonce;
    String hashPath = 'tx/';
    late Widget transactionTypeContent;
    switch (entryType) {
      case XelisWalletCoinbaseEntry():
        hashPath = 'block/';
        transactionTypeContent = CoinbaseEntryContent(entryType);
      case XelisWalletBurnEntry():
        nonce = entryType.nonce;
        transactionTypeContent = BurnEntryContent(entryType);
      case XelisWalletIncomingEntry():
        transactionTypeContent = IncomingEntryContent(entryType);
      case XelisWalletOutgoingEntry():
        nonce = entryType.nonce;
        transactionTypeContent = OutgoingEntryContent(
          entryType,
          exactDestinations: exactDestinations,
        );
      case XelisWalletMultisigEntry():
        nonce = entryType.nonce;
        transactionTypeContent = MultisigEntryContent(entryType);
      case XelisWalletInvokeContractEntry():
        nonce = entryType.nonce;
        transactionTypeContent = InvokeContractEntryContent(entryType);
      case XelisWalletDeployContractEntry():
        nonce = entryType.nonce;
        transactionTypeContent = DeployContractEntryContent(entryType);
      case XelisWalletIncomingContractEntry():
        transactionTypeContent = IncomingContractEntryContent(entryType);
      case XelisWalletIncomingBlobEntry():
        transactionTypeContent = BlobEntryContent.incoming(entryType);
      case XelisWalletOutgoingBlobEntry():
        nonce = entryType.nonce;
        transactionTypeContent = BlobEntryContent.outgoing(
          entryType,
          exactDestinations: exactDestinations,
        );
    }

    final url = detail.isPending
        ? null
        : switch (network) {
            XelisNetwork.mainnet => Uri.parse(
              '${AppResources.explorerMainnetUrl}$hashPath${detail.hash}',
            ),
            XelisNetwork.testnet ||
            XelisNetwork.devnet ||
            XelisNetwork.stagenet => Uri.parse(
              '${AppResources.explorerTestnetUrl}$hashPath${detail.hash}',
            ),
          };

    final displayTimestamp = formatPrettyTimestamp(
      walletTimestampToDateTime(detail.timestampMillis),
      locale,
    );
    final displayTopoheight = detail.topoheight == null
        ? null
        : formatBigInt(detail.topoheight!);

    return FScaffold(
      header: FHeader.nested(
        title: Text(loc.transaction),
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction(
              icon: const Icon(FLucideIcons.arrowLeft),
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
                          hash: detail.hash,
                          type: txInfo.label,
                          color: txInfo.color,
                          icon: txInfo.icon,
                          timestamp: displayTimestamp,
                          topoheight: displayTopoheight,
                          url: url,
                          isPending: detail.isPending,
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

  Widget _buildStatusScaffold(
    BuildContext context,
    AppLocalizations loc, {
    required Widget child,
  }) {
    return FScaffold(
      header: FHeader.nested(
        title: Text(loc.transaction),
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction(
              icon: const Icon(FLucideIcons.arrowLeft),
              onPress: () => context.pop(),
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Spaces.medium),
          child: child,
        ),
      ),
    );
  }
}
