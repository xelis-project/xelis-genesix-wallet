import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/assets_dropdown_menu_item.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown.dart';
import 'package:go_router/go_router.dart';

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
    final assets = ref.watch(
      walletStateProvider.select((state) => state.assets),
    );
    final filterState = ref.watch(
      settingsProvider.select((state) => state.historyFilterState),
    );
    final selectedCategories = _getSelectedCategories(filterState);
    final hideExtraData = filterState.hideExtraData;
    final hideZeroBalance = filterState.hideZeroTransfer;

    List<DropdownMenuItem<String?>> assetItems = [
      DropdownMenuItem(value: null, child: Text(loc.all)),
    ];
    assetItems.addAll(
      assets.entries
          .map(
            (asset) =>
                AssetsDropdownMenuItem.fromMapEntry(asset, showBalance: false),
          )
          .toList(),
    );

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
            Text(loc.asset, style: context.titleSmall),
            const SizedBox(height: Spaces.small),
            GenericFormBuilderDropdown<String?>(
              name: 'asset',
              initialValue: assetItems.first.value,
              dropdownColor: Colors.black,
              items: assetItems,
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
          child: TextButton(
            onPressed: () {
              _saveFilter();
              context.pop(true);
            },
            child: Text(loc.save),
          ),
        ),
      ],
    );
  }

  void _saveFilter() {
    if (_formKey.currentState!.saveAndValidate()) {
      final selectedCategories =
          _formKey.currentState!.fields['category']!.value as List<String>;
      final hideExtraData =
          _formKey.currentState!.fields['hide_extra_data']!.value as bool;
      final hideZeroBalance =
          _formKey.currentState!.fields['hide_zero_balance']!.value as bool;
      final selectedAsset =
          _formKey.currentState!.fields['asset']!.value as String?;

      final filterState = HistoryFilterState(
        showIncoming: selectedCategories.contains('incoming'),
        showOutgoing: selectedCategories.contains('outgoing'),
        showBurn: selectedCategories.contains('burn'),
        showCoinbase: selectedCategories.contains('coinbase'),
        hideExtraData: hideExtraData,
        hideZeroTransfer: hideZeroBalance,
        asset: selectedAsset,
      );

      ref.read(settingsProvider.notifier).setHistoryFilterState(filterState);
    }
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
