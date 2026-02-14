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
import 'package:intl/intl.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class FiltersDialog extends ConsumerStatefulWidget {
  const FiltersDialog(
    this.addressBook, {
    super.key,
    this.title,
    this.applyLabel,
    this.persistToSettings = true,
  });

  final Map<String, ContactDetails> addressBook;
  final String? title;
  final String? applyLabel;
  final bool persistToSettings;

  @override
  ConsumerState createState() => _FiltersDialogState();
}

class _FiltersDialogState extends ConsumerState<FiltersDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late Set<TransactionCategory> _categoriesSelected;
  late final FSelectController<MapEntry<String, AssetData>> _assetController;
  late final FSelectController<ContactDetails> _contactController;
  final _scrollController = ScrollController();
  late bool _hideExtraData;
  late bool _hideZeroBalance;
  DateTime? _minTimestamp;
  DateTime? _maxTimestamp;
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(
      settingsProvider.select((state) => state.historyFilterState),
    );
    _categoriesSelected = _getSelectedCategories(filterState);

    final knownAssets = ref.read(walletStateProvider).knownAssets;

    MapEntry<String, AssetData>? initialAssetEntry;
    if (filterState.asset != null) {
      final matches = knownAssets.entries.where(
        (e) => e.key == filterState.asset,
      );
      if (matches.isNotEmpty) initialAssetEntry = matches.first;
    }

    ContactDetails? initialContact;
    if (filterState.address != null) {
      final matches = widget.addressBook.values.where(
        (c) => c.address == filterState.address,
      );
      if (matches.isNotEmpty) initialContact = matches.first;
    }

    _assetController = FSelectController<MapEntry<String, AssetData>>(
      value: initialAssetEntry,
    );
    _contactController = FSelectController<ContactDetails>(
      value: initialContact,
    );
    _hideExtraData = filterState.hideExtraData;
    _hideZeroBalance = filterState.hideZeroTransfer;
    _minTimestamp = filterState.minTimestamp;
    _maxTimestamp = filterState.maxTimestamp;
    _fromDateController.text = _formatDate(filterState.minTimestamp);
    _toDateController.text = _formatDate(filterState.maxTimestamp);
  }

  @override
  void dispose() {
    _assetController.dispose();
    _contactController.dispose();
    _scrollController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
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

    final titleText = widget.title ?? loc.filters;
    final applyText = widget.applyLabel ?? loc.apply;

    return FDialog(
      direction: Axis.horizontal,
      title: Text(titleText),
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
                    control: .lifted(
                      value: _categoriesSelected,
                      onChange: (values) =>
                          setState(() => _categoriesSelected = values),
                    ),
                    label: Text(loc.category),
                    validator: (values) => values?.isEmpty ?? true
                        ? loc.category_select_error
                        : null,
                    children: [
                      FSelectTile(
                        title: Text(loc.incoming),
                        value: TransactionCategory.incoming,
                        subtitle: Text(loc.category_incoming_subtitle),
                      ),
                      FSelectTile(
                        title: Text(loc.outgoing),
                        value: TransactionCategory.outgoing,
                        subtitle: Text(loc.category_outgoing_subtitle),
                      ),
                      FSelectTile(
                        title: Text(loc.coinbase),
                        value: TransactionCategory.coinbase,
                        subtitle: Text(loc.category_coinbase_subtitle),
                      ),
                      FSelectTile(
                        title: Text(loc.burn),
                        value: TransactionCategory.burn,
                        subtitle: Text(loc.category_burn_subtitle),
                      ),
                    ],
                  ),
                  // Asset selection
                  FSelect<MapEntry<String, AssetData>>.searchBuilder(
                    label: Text(loc.asset),
                    hint: loc.select_asset,
                    control: .managed(controller: _assetController),
                    format: (assetEntry) => assetEntry.value.name,
                    clearable: true,
                    filter: (query) {
                      if (query.isEmpty) return trackedAssets;
                      final q = query.toLowerCase();
                      return trackedAssets.where(
                        (e) => e.value.name.toLowerCase().contains(q),
                      );
                    },
                    contentBuilder: (context, query, values) {
                      return values
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
                    hint: loc.select_contract,
                    control: .managed(controller: _contactController),
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
                  FCard(
                    child: Column(
                      spacing: Spaces.medium,
                      children: [
                        FTextField(
                          label: Text(loc.from_date),
                          hint: loc.select_start_date,
                          readOnly: true,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          control: .managed(controller: _fromDateController),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _minTimestamp ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _minTimestamp = date;
                                _fromDateController.text = _formatDate(date);
                              });
                            }
                          },
                          suffixBuilder: _minTimestamp != null
                              ? (_, _, _) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      _minTimestamp = null;
                                      _fromDateController.text = '';
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      FIcons.x,
                                      size: 14,
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        FTextField(
                          label: Text(loc.to_date),
                          hint: loc.select_end_date,
                          readOnly: true,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          control: .managed(controller: _toDateController),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _maxTimestamp ?? DateTime.now(),
                              firstDate: _minTimestamp ?? DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _maxTimestamp = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  23,
                                  59,
                                  59,
                                  999,
                                );
                                _toDateController.text = _formatDate(date);
                              });
                            }
                          },
                          suffixBuilder: _maxTimestamp != null
                              ? (_, _, _) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      _maxTimestamp = null;
                                      _toDateController.text = '';
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      FIcons.x,
                                      size: 14,
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  // Other options
                  FCard(
                    child: Column(
                      spacing: Spaces.medium,
                      children: [
                        FSwitch(
                          label: Text(loc.hide_extra_data),
                          description: Text(loc.hide_extra_data_description),
                          value: _hideExtraData,
                          onChange: (value) {
                            setState(() {
                              _hideExtraData = value;
                            });
                          },
                        ),
                        FSwitch(
                          label: Text(loc.hide_zero_transfers),
                          description: Text(loc.hide_transactions_zero_value),
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
        FButton(onPress: _applyFilters, child: Text(applyText)),
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
      _categoriesSelected = {
        TransactionCategory.incoming,
        TransactionCategory.outgoing,
        TransactionCategory.coinbase,
        TransactionCategory.burn,
      };
      _assetController.value = null;
      _contactController.value = null;
      _hideExtraData = false;
      _hideZeroBalance = false;
      _minTimestamp = null;
      _maxTimestamp = null;
      _fromDateController.text = '';
      _toDateController.text = '';
    });
    ref.read(searchQueryProvider.notifier).clear();
  }

  void _applyFilters() {
    if (_formKey.currentState?.validate() ?? false) {
      final assetEntry = _assetController.value;
      final contact = _contactController.value;

      final newFilterState = HistoryFilterState(
        hideExtraData: _hideExtraData,
        hideZeroTransfer: _hideZeroBalance,
        showIncoming: _categoriesSelected.contains(
          TransactionCategory.incoming,
        ),
        showOutgoing: _categoriesSelected.contains(
          TransactionCategory.outgoing,
        ),
        showCoinbase: _categoriesSelected.contains(
          TransactionCategory.coinbase,
        ),
        showBurn: _categoriesSelected.contains(TransactionCategory.burn),
        asset: assetEntry?.key,
        address: contact?.address,
        minTimestamp: _minTimestamp,
        maxTimestamp: _maxTimestamp,
      );
      if (widget.persistToSettings) {
        ref
            .read(settingsProvider.notifier)
            .setHistoryFilterState(newFilterState);
      }
      context.pop(newFilterState);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat.yMd().format(value);
  }
}
