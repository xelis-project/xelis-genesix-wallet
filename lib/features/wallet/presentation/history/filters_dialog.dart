import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
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
  static final DateTime _earliestHistoryFilterDate = DateTime.utc(2024);

  final _formKey = GlobalKey<FormState>();
  late Set<TransactionCategory> _categoriesSelected;
  late final FSelectController<MapEntry<String, AssetData>> _assetController;
  late final FSelectController<ContactDetails> _contactController;
  final _scrollController = ScrollController();
  late bool _hideExtraData;
  late bool _hideZeroBalance;
  DateTime? _minTimestamp;
  DateTime? _maxTimestamp;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(
      settingsProvider.select((state) => state.historyFilterState),
    );
    _categoriesSelected = _getSelectedCategories(filterState);

    final knownAssets = ref.read(walletRuntimeProvider).knownAssets;

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
  }

  @override
  void dispose() {
    _assetController.dispose();
    _contactController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final balances = ref.watch(
      walletRuntimeProvider.select((state) => state.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.watch(
      walletRuntimeProvider.select((value) => value.knownAssets),
    );

    final trackedAssets = assets.entries
        .where((entry) => balances.containsKey(entry.key))
        .toList();

    final titleText = widget.title ?? loc.filters;
    final applyText = widget.applyLabel ?? loc.apply;
    final today = _calendarDate(DateTime.now())!;

    return FDialog(
      clipBehavior: Clip.antiAlias,
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
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      spacing: Spaces.medium,
                      children: [
                        FDateField.calendar(
                          label: Text(loc.from_date),
                          hint: loc.select_start_date,
                          clearable: true,
                          start: _earliestHistoryFilterDate,
                          end: _exclusiveCalendarEnd(
                            _calendarDate(_maxTimestamp) ?? today,
                          ),
                          today: today,
                          format: _formatCalendarDate,
                          control: .lifted(
                            date: _calendarDate(_minTimestamp),
                            onChange: _setMinTimestamp,
                          ),
                        ),
                        FDateField.calendar(
                          label: Text(loc.to_date),
                          hint: loc.select_end_date,
                          clearable: true,
                          start:
                              _calendarDate(_minTimestamp) ??
                              _earliestHistoryFilterDate,
                          end: _exclusiveCalendarEnd(today),
                          today: today,
                          format: _formatCalendarDate,
                          control: .lifted(
                            date: _calendarDate(_maxTimestamp),
                            onChange: _setMaxTimestamp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Other options
                  FCard(
                    clipBehavior: Clip.antiAlias,
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
          variant: .outline,
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

  void _setMinTimestamp(DateTime? value) {
    setState(() {
      _minTimestamp = _localStartOfDay(value);
      if (_minTimestamp != null &&
          _maxTimestamp != null &&
          _calendarDate(
            _maxTimestamp,
          )!.isBefore(_calendarDate(_minTimestamp)!)) {
        _maxTimestamp = null;
      }
    });
  }

  void _setMaxTimestamp(DateTime? value) {
    setState(() => _maxTimestamp = _localEndOfDay(value));
  }

  String _formatCalendarDate(
    BuildContext context,
    DateTime value,
    DateFormat _,
  ) {
    final localeName = FLocalizations.of(context)?.localeName;
    return DateFormat.yMd(localeName).format(value);
  }

  DateTime? _calendarDate(DateTime? value) {
    if (value == null) return null;
    return DateTime.utc(value.year, value.month, value.day);
  }

  DateTime _exclusiveCalendarEnd(DateTime inclusiveEnd) {
    return inclusiveEnd.add(const Duration(days: 1));
  }

  DateTime? _localStartOfDay(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _localEndOfDay(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}
