import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/assets_dropdown_menu_item.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/burn_review_dialog.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/features/wallet/presentation/settings_tab/components/burn_warning_widget.dart';
import 'package:loader_overlay/loader_overlay.dart';

class BurnScreen extends ConsumerStatefulWidget {
  const BurnScreen({super.key});

  @override
  ConsumerState createState() => _BurnScreenState();
}

class _BurnScreenState extends ConsumerState<BurnScreen> {
  final _burnFormKey = GlobalKey<FormBuilderState>(debugLabel: '_burnFormKey');
  late String _selectedAssetBalance;

  late FocusNode _focusNodeAmount;

  @override
  void initState() {
    super.initState();
    _focusNodeAmount = FocusNode();
    final Map<String, String> assets =
        ref.read(walletStateProvider.select((value) => value.assets));
    _selectedAssetBalance = assets[assets.entries.first.key]!;
  }

  @override
  dispose() {
    _focusNodeAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final Map<String, String> assets =
        ref.watch(walletStateProvider.select((value) => value.assets));

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.burn),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          Spaces.large,
          Spaces.none,
          Spaces.large,
          Spaces.large,
        ),
        children: [
          BurnWarningWidget(loc.burn_screen_warning_message),
          const SizedBox(height: Spaces.extraLarge),
          FormBuilder(
            key: _burnFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.amount.capitalize(),
                  style: context.titleMedium,
                ),
                const SizedBox(height: Spaces.small),
                FormBuilderTextField(
                  name: 'amount',
                  focusNode: _focusNodeAmount,
                  style: context.headlineLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                  autocorrect: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: context.textInputDecoration.copyWith(
                    labelText: AppResources.zeroBalance,
                    labelStyle: context.headlineLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(Spaces.small),
                      child: TextButton(
                        onPressed: () => _burnFormKey
                            .currentState?.fields['amount']
                            ?.didChange(_selectedAssetBalance),
                        child: Text(loc.max),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    // workaround to reset the error message when the user modifies the field
                    final hasError =
                        _burnFormKey.currentState?.fields['amount']?.hasError;
                    if (hasError ?? false) {
                      _burnFormKey.currentState?.fields['amount']?.reset();
                    }
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: loc.field_required_error),
                    FormBuilderValidators.numeric(
                        errorText: loc.must_be_numeric_error),
                    (val) {
                      if (val != null) {
                        final amount = double.tryParse(val);
                        if (amount == null || amount == 0) {
                          return loc.invalid_amount_error;
                        }
                      }
                      return null;
                    }
                  ]),
                ),
                const SizedBox(height: Spaces.large),
                Text(
                  loc.asset,
                  style: context.titleMedium,
                ),
                const SizedBox(height: Spaces.small),
                FormBuilderDropdown<String>(
                  name: 'assets',
                  initialValue: assets.entries.first.key,
                  items: assets.entries
                      .map(
                          (asset) => AssetsDropdownMenuItem.fromMapEntry(asset))
                      .toList(),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: loc.field_required_error),
                  ]),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedAssetBalance = assets[val]!;
                      });
                    }
                    // workaround to reset the error message when the user modifies the field
                    final hasError =
                        _burnFormKey.currentState?.fields['assets']?.hasError;
                    if (hasError ?? false) {
                      _burnFormKey.currentState?.fields['assets']?.reset();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Spaces.extraLarge),
          Row(
            children: [
              if (context.isWideScreen) const Spacer(),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.check_circle),
                  onPressed: _reviewBurn,
                  label: Text(loc.review_burn),
                ),
              ),
              if (context.isWideScreen) const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  void _reviewBurn() async {
    if (_selectedAssetBalance == AppResources.zeroBalance) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError(loc.no_balance_to_burn);
      return;
    }

    if (_burnFormKey.currentState?.saveAndValidate() ?? false) {
      final amount =
          _burnFormKey.currentState?.fields['amount']?.value as String;
      final asset =
          _burnFormKey.currentState?.fields['assets']?.value as String;

      _focusNodeAmount.unfocus();

      context.loaderOverlay.show();

      TransactionSummary? tx;
      if (amount.trim() == _selectedAssetBalance) {
        tx = await ref
            .read(walletStateProvider.notifier)
            .createBurnAllTransaction(asset: asset);
      } else {
        tx = await ref
            .read(walletStateProvider.notifier)
            .createBurnTransaction(amount: double.parse(amount), asset: asset);
      }

      if (mounted && tx != null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return BurnReviewDialog(tx!);
          },
        );
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
