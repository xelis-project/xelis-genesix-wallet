import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class FiltersDialog extends ConsumerStatefulWidget {
  const FiltersDialog(this.addressBook, {super.key});

  final Map<String, ContactDetails> addressBook;

  @override
  ConsumerState createState() => _FiltersDialogState();
}

class _FiltersDialogState extends ConsumerState<FiltersDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _categoriesController =
      FSelectTileGroupController<TransactionCategory>();
  late final _assetController = FSelectController<MapEntry<String, AssetData>>(
    vsync: this,
  );
  late final _contactController = FSelectController<ContactDetails>(
    vsync: this,
  );
  final _scrollController = ScrollController();
  late bool _hideExtraData;
  late bool _hideZeroBalance;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(
      settingsProvider.select((state) => state.historyFilterState),
    );
    _categoriesController.value = _getSelectedCategories(filterState);
    _assetController.value = filterState.asset != null
        ? ref
              .read(walletStateProvider)
              .knownAssets
              .entries
              .firstWhere((entry) => entry.key == filterState.asset)
        : null;
    _contactController.value = filterState.address != null
        ? widget.addressBook.values.firstWhere(
            (contact) => contact.address == filterState.address,
          )
        : null;
    _hideExtraData = filterState.hideExtraData;
    _hideZeroBalance = filterState.hideZeroTransfer;
  }

  @override
  void dispose() {
    _categoriesController.dispose();
    _assetController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );

    final trackedAssets = assets.entries
        .where((entry) => balances.containsKey(entry.key))
        .toList();

    return FDialog(
      direction: Axis.horizontal,
      title: Text(loc.filters),
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.mediaHeight * 0.6),
        child: FadedScroll(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: Spaces.large,
                children: [
                  // Categories selection
                  FSelectTileGroup(
                    selectController: _categoriesController,
                    label: Text(loc.category),
                    validator: (values) => values?.isEmpty ?? true
                        ? 'Please select at least one category.'
                        : null,
                    children: [
                      FSelectTile(
                        title: Text(loc.incoming),
                        value: TransactionCategory.incoming,
                        subtitle: Text(
                          'Transactions where you received assets.',
                        ),
                      ),
                      FSelectTile(
                        title: Text(loc.outgoing),
                        value: TransactionCategory.outgoing,
                        subtitle: Text('Transactions initiated by you.'),
                      ),
                      FSelectTile(
                        title: Text(loc.coinbase),
                        value: TransactionCategory.coinbase,
                        subtitle: Text(
                          'Transactions where you received rewards.',
                        ),
                      ),
                      FSelectTile(
                        title: Text(loc.burn),
                        value: TransactionCategory.burn,
                        subtitle: Text('Transactions where you burned assets.'),
                      ),
                    ],
                  ),
                  // Asset selection
                  FSelect<MapEntry<String, AssetData>>.searchBuilder(
                    label: Text(loc.asset),
                    hint: 'Select a asset',
                    controller: _assetController,
                    format: (assetEntry) => assetEntry.value.name,
                    clearable: true,
                    filter: (query) => query.isEmpty
                        ? trackedAssets
                        : trackedAssets
                              .where(
                                (assetEntry) => assetEntry.value.name
                                    .toLowerCase()
                                    .contains(query.toLowerCase()),
                              )
                              .toList(),
                    contentBuilder: (context, style, data) {
                      return data
                          .map(
                            (assetEntry) =>
                                FSelectItem<MapEntry<String, AssetData>>(
                                  title: Text(assetEntry.value.name),
                                  value: assetEntry,
                                ),
                          )
                          .toList();
                    },
                  ),
                  // Contact selection
                  FSelect<ContactDetails>.searchBuilder(
                    label: Text(loc.contact),
                    hint: 'Select a contact',
                    controller: _contactController,
                    format: (contact) => contact.name,
                    clearable: true,
                    filter: (query) async {
                      if (query.isNotEmpty) {
                        ref.read(searchQueryProvider.notifier).change(query);
                      }
                      final addressBook = await ref.read(
                        addressBookProvider.future,
                      );
                      return addressBook.values;
                    },
                    contentBuilder: (context, style, data) {
                      return data
                          .map(
                            (contact) => FSelectItem<ContactDetails>(
                              title: Text(contact.name),
                              value: contact,
                            ),
                          )
                          .toList();
                    },
                  ),
                  // Other options
                  FCard(
                    child: Column(
                      spacing: Spaces.medium,
                      children: [
                        FSwitch(
                          label: Text(loc.hide_extra_data),
                          description: Text(
                            'Hide extra data in transaction details.',
                          ),
                          value: _hideExtraData,
                          onChange: (value) {
                            setState(() {
                              _hideExtraData = value;
                            });
                          },
                        ),
                        FSwitch(
                          label: Text(loc.hide_zero_transfers),
                          description: Text(
                            'Hide transactions with zero balance transfers.',
                          ),
                          value: _hideZeroBalance,
                          onChange: (value) {
                            setState(() {
                              _hideZeroBalance = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: _resetFilters,
          child: Text(loc.reset_all),
        ),
        FButton(onPress: _applyFilters, child: Text(loc.apply)),
      ],
    );
  }

  Set<TransactionCategory> _getSelectedCategories(
    HistoryFilterState filterState,
  ) {
    return {
      if (filterState.showIncoming) TransactionCategory.incoming,
      if (filterState.showOutgoing) TransactionCategory.outgoing,
      if (filterState.showCoinbase) TransactionCategory.coinbase,
      if (filterState.showBurn) TransactionCategory.burn,
    };
  }

  void _resetFilters() {
    setState(() {
      _categoriesController.value = {
        TransactionCategory.incoming,
        TransactionCategory.outgoing,
        TransactionCategory.coinbase,
        TransactionCategory.burn,
      };
      _assetController.value = null;
      _contactController.value = null;
      _hideExtraData = false;
      _hideZeroBalance = false;
    });
    ref.read(searchQueryProvider.notifier).clear();
    _applyFilters();
  }

  void _applyFilters() {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedCategories = _categoriesController.value;
      final assetEntry = _assetController.value;
      final contact = _contactController.value;

      final newFilterState = HistoryFilterState(
        hideExtraData: _hideExtraData,
        hideZeroTransfer: _hideZeroBalance,
        showIncoming: selectedCategories.contains(TransactionCategory.incoming),
        showOutgoing: selectedCategories.contains(TransactionCategory.outgoing),
        showCoinbase: selectedCategories.contains(TransactionCategory.coinbase),
        showBurn: selectedCategories.contains(TransactionCategory.burn),
        asset: assetEntry?.key,
        address: contact?.address,
      );

      ref.read(settingsProvider.notifier).setHistoryFilterState(newFilterState);
      context.pop(true);
    }
  }
}
