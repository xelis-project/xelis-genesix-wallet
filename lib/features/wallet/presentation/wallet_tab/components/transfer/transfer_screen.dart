import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/assets_dropdown_menu_item.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/transfer/transfer_review_dialog.dart';
import 'package:genesix/rust_bridge/api/utils.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown.dart';
import 'package:loader_overlay/loader_overlay.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _transferFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_transferFormKey');
  late String _selectedAssetBalance;
  late FocusNode _focusNodeAmount;
  late FocusNode _focusNodeAddress;
  String _estimatedFee = AppResources.zeroBalance;
  bool _isFeeEstimated = false;

  @override
  void initState() {
    super.initState();
    _focusNodeAmount = FocusNode();
    _focusNodeAddress = FocusNode();
    final Map<String, String> assets =
        ref.read(walletStateProvider.select((value) => value.assets));
    _selectedAssetBalance = assets[assets.entries.first.key]!;
  }

  @override
  dispose() {
    _focusNodeAmount.dispose();
    _focusNodeAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final Map<String, String> assets =
        ref.watch(walletStateProvider.select((value) => value.assets));

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.transfer),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            Spaces.large, Spaces.none, Spaces.large, Spaces.large),
        children: [
          Text(
            loc.transfer_screen_message,
            style: context.titleMedium
                ?.copyWith(color: context.moreColors.mutedColor),
          ),
          const SizedBox(height: Spaces.extraLarge),
          FormBuilder(
            key: _transferFormKey,
            onChanged: _updateEstimatedFee,
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
                        onPressed: () => _transferFormKey
                            .currentState?.fields['amount']
                            ?.didChange(_selectedAssetBalance),
                        child: Text(loc.max),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    // workaround to reset the error message when the user modifies the field
                    final hasError = _transferFormKey
                        .currentState?.fields['amount']?.hasError;
                    if (hasError ?? false) {
                      _transferFormKey.currentState?.fields['amount']?.reset();
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
                GenericFormBuilderDropdown<String>(
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
                    final hasError = _transferFormKey
                        .currentState?.fields['assets']?.hasError;
                    if (hasError ?? false) {
                      _transferFormKey.currentState?.fields['assets']?.reset();
                    }
                  },
                ),
                const SizedBox(height: Spaces.large),
                Text(
                  loc.destination,
                  style: context.titleMedium,
                ),
                const SizedBox(height: Spaces.small),
                FormBuilderTextField(
                  name: 'address',
                  focusNode: _focusNodeAddress,
                  style: context.bodyMedium,
                  autocorrect: false,
                  keyboardType: TextInputType.text,
                  decoration: context.textInputDecoration.copyWith(
                    labelText: loc.receiver_address,
                  ),
                  onChanged: (value) {
                    // workaround to reset the error message when the user modifies the field
                    final hasError = _transferFormKey
                        .currentState?.fields['address']?.hasError;
                    if (hasError ?? false) {
                      _transferFormKey.currentState?.fields['address']?.reset();
                    }
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: loc.field_required_error),
                    (val) {
                      if (val != null &&
                          !isAddressValid(strAddress: val.trim())) {
                        return loc.invalid_address_format_error;
                      }
                      return null;
                    }
                  ]),
                ),
                const SizedBox(height: Spaces.extraLarge),
                Row(
                  children: [
                    Text(
                      loc.estimated_fee,
                      style: context.titleMedium,
                    ),
                    const SizedBox(width: Spaces.small),
                    Text(
                      '$_estimatedFee ${AppResources.xelisAsset.ticker}',
                      style: context.titleMedium
                          ?.copyWith(color: context.moreColors.mutedColor),
                    ),
                  ],
                ),
                const SizedBox(height: Spaces.large),
                Text(
                  loc.boost_fees_title,
                  style: context.titleMedium,
                ),
                Text(loc.boost_fees_message,
                    style: context.labelMedium
                        ?.copyWith(color: context.moreColors.mutedColor)),
                const SizedBox(height: Spaces.small),
                FormBuilderSlider(
                  name: 'fee',
                  initialValue: 1,
                  min: 1,
                  max: 5,
                  divisions: 40,
                  displayValues: DisplayValues.current,
                  enabled: _isFeeEstimated,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.all(Spaces.none),
                  ),
                  valueWidget: (value) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spaces.small),
                      child: Text(
                        'x$value',
                        style: context.bodyLarge,
                      ),
                    );
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
                flex: 2,
                child: TextButton.icon(
                  icon: const Icon(Icons.check_circle),
                  onPressed: _reviewTransfer,
                  label: Text(loc.review_send),
                ),
              ),
              if (context.isWideScreen) const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  void _reviewTransfer() async {
    if (_selectedAssetBalance == AppResources.zeroBalance) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError(loc.no_balance_to_transfer);
      return;
    }

    if (_transferFormKey.currentState?.saveAndValidate() ?? false) {
      final amount =
          _transferFormKey.currentState?.fields['amount']?.value as String;
      final address =
          _transferFormKey.currentState?.fields['address']?.value as String;
      final asset =
          _transferFormKey.currentState?.fields['assets']?.value as String;

      _unfocusNodes();

      context.loaderOverlay.show();

      TransactionSummary? tx;
      if (amount.trim() == _selectedAssetBalance) {
        tx = await ref
            .read(walletStateProvider.notifier)
            .createAllXelisTransaction(
                destination: address.trim(), asset: asset);
      } else {
        tx =
            await ref.read(walletStateProvider.notifier).createXelisTransaction(
                  amount: double.parse(amount),
                  destination: address.trim(),
                  asset: asset,
                );
      }

      if (mounted && tx != null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return TransferReviewDialog(tx!);
          },
        );
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  void _unfocusNodes() {
    _focusNodeAmount.unfocus();
    _focusNodeAddress.unfocus();
  }

  void _updateEstimatedFee() {
    if (_transferFormKey.currentState?.isValid ?? false) {
      final amount =
          _transferFormKey.currentState?.fields['amount']?.value as String;
      final address =
          _transferFormKey.currentState?.fields['address']?.value as String;
      final asset =
          _transferFormKey.currentState?.fields['assets']?.value as String;
      ref
          .read(walletStateProvider.notifier)
          .estimateFees(
            amount: double.parse(amount),
            destination: address.trim(),
            asset: asset,
          )
          .then((value) {
        setState(() {
          final estimatedFee = double.parse(value);
          _isFeeEstimated = estimatedFee > 0;
          final multiplier =
              _transferFormKey.currentState?.fields['fee']?.value as double;
          _estimatedFee = (estimatedFee * multiplier)
              .toStringAsFixed(AppResources.xelisDecimals);
        });
      });
    } else {
      setState(() {
        _isFeeEstimated = false;
        _estimatedFee = AppResources.zeroBalance;
      });
    }
  }
}
