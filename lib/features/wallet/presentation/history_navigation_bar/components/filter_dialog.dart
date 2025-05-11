import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/contact_dropdown_menu_item.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/asset_dropdown_menu_item.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class FilterDialog extends ConsumerStatefulWidget {
  const FilterDialog({super.key});

  @override
  ConsumerState createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  final _formKey = GlobalKey<FormBuilderState>(debugLabel: '_filterFormKey');

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final future = ref.watch(addressBookProvider.future);
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );
    final filterState = ref.watch(
      settingsProvider.select((state) => state.historyFilterState),
    );
    final selectedCategories = _getSelectedCategories(filterState);
    final hideExtraData = filterState.hideExtraData;
    final hideZeroBalance = filterState.hideZeroTransfer;

    return GenericDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  loc.history_filters,
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () => context.pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.category, style: context.titleSmall),
            const SizedBox(height: Spaces.small),
            FormBuilderFilterChips(
              name: 'category',
              runSpacing: Spaces.small,
              spacing: Spaces.small,
              alignment: WrapAlignment.center,
              initialValue: selectedCategories,
              options: [
                FormBuilderChipOption(
                  value: 'incoming',
                  child: Text(loc.incoming),
                ),
                FormBuilderChipOption(
                  value: 'outgoing',
                  child: Text(loc.outgoing),
                ),
                FormBuilderChipOption(value: 'burn', child: Text(loc.burn)),
                FormBuilderChipOption(
                  value: 'coinbase',
                  child: Text(loc.coinbase),
                ),
              ],
            ),
            const SizedBox(height: Spaces.medium),
            FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  Map<String?, DropdownMenuItem<String?>> contactItems = {
                    null: DropdownMenuItem(value: null, child: Text(loc.all)),
                  };

                  List<Widget> selectedContacts = [
                    Text(
                      loc.all,
                      style: context.bodyLarge?.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                  ];

                  for (final contact in snapshot.data!.entries) {
                    contactItems[contact.key] =
                        ContactDropdownMenuItem.fromMapEntry(context, contact);
                    selectedContacts.add(
                      Text(
                        contact.value.name,
                        style: context.bodyLarge?.copyWith(
                          color: context.colors.onSurface,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact', style: context.titleSmall),
                      const SizedBox(height: Spaces.small),
                      GenericFormBuilderDropdown<String?>(
                        name: 'contact',
                        initialValue: contactItems[filterState.address]?.value,
                        dropdownColor: Colors.black,
                        items: contactItems.values.toList(),
                        selectedItems: selectedContacts,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Builder(
              builder: (context) {
                Map<String?, DropdownMenuItem<String?>> assetItems = {
                  null: DropdownMenuItem(value: null, child: Text(loc.all)),
                };
                balances.forEach((key, value) {
                  assetItems[key] = AssetDropdownMenuItem.fromMapEntry(
                    MapEntry(key, value),
                    assets[key]!,
                    showBalance: false,
                  );
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Spaces.medium),
                    Text(loc.asset, style: context.titleSmall),
                    const SizedBox(height: Spaces.small),
                    GenericFormBuilderDropdown<String?>(
                      name: 'asset',
                      initialValue: assetItems[filterState.asset]?.value,
                      dropdownColor: Colors.black,
                      items: assetItems.values.toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: Spaces.medium),
            Text(loc.others, style: context.titleSmall),
            const SizedBox(height: Spaces.small),
            FormBuilderCheckbox(
              initialValue: hideExtraData,
              name: 'hide_extra_data',
              title: Text(loc.hide_extra_data, style: context.bodyMedium),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: Spaces.medium),
            FormBuilderCheckbox(
              initialValue: hideZeroBalance,
              name: 'hide_zero_balance',
              title: Text(loc.hide_zero_transfers, style: context.bodyMedium),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: OutlinedButton(
            onPressed: _resetFilters,
            child: Text('Reset All'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: TextButton(
            onPressed: () {
              _saveFilters();
              context.pop(true);
            },
            child: Text('Apply'),
          ),
        ),
      ],
    );
  }

  void _saveFilters() {
    if (_formKey.currentState!.saveAndValidate()) {
      final selectedCategories =
          _formKey.currentState!.fields['category']!.value as List<String>;
      final hideExtraData =
          _formKey.currentState!.fields['hide_extra_data']!.value as bool;
      final hideZeroBalance =
          _formKey.currentState!.fields['hide_zero_balance']!.value as bool;
      final selectedAsset =
          _formKey.currentState!.fields['asset']!.value as String?;
      final selectedContact =
          _formKey.currentState!.fields['contact']?.value as String?;

      final filterState = HistoryFilterState(
        showIncoming: selectedCategories.contains('incoming'),
        showOutgoing: selectedCategories.contains('outgoing'),
        showBurn: selectedCategories.contains('burn'),
        showCoinbase: selectedCategories.contains('coinbase'),
        hideExtraData: hideExtraData,
        hideZeroTransfer: hideZeroBalance,
        asset: selectedAsset,
        address: selectedContact,
      );

      ref.read(settingsProvider.notifier).setHistoryFilterState(filterState);
    }
  }

  void _resetFilters() {
    _formKey.currentState?.fields['category']?.didChange([
      'incoming',
      'outgoing',
      'burn',
      'coinbase',
    ]);
    _formKey.currentState?.fields['asset']?.didChange(null);
    _formKey.currentState?.fields['contact']?.didChange(null);
    _formKey.currentState?.fields['hide_extra_data']?.didChange(false);
    _formKey.currentState?.fields['hide_zero_balance']?.didChange(false);
  }

  List<String> _getSelectedCategories(HistoryFilterState filterState) {
    return [
      if (filterState.showIncoming) 'incoming',
      if (filterState.showOutgoing) 'outgoing',
      if (filterState.showBurn) 'burn',
      if (filterState.showCoinbase) 'coinbase',
    ];
  }
}
