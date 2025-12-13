import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/address_book/select_address_dialog_old.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/asset_dropdown_menu_item_old.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transaction_dialog_old.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/input_decoration_old.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget_old.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown_old.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.recipientAddress});

  final String? recipientAddress;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _transferFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_transferFormKey',
  );
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
    final Map<String, String> balances = ref.read(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.read(
      walletStateProvider.select((value) => value.knownAssets),
    );

    // Get first balance that has corresponding asset data
    final firstValidBalance = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .firstOrNull;

    if (firstValidBalance != null) {
      _selectedAssetBalance = firstValidBalance.value;
    } else {
      _selectedAssetBalance = AppResources.zeroBalance;
    }

    // Pre-fill address if provided
    if (widget.recipientAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transferFormKey.currentState?.fields['address']?.didChange(
          widget.recipientAddress,
        );
      });
    }
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
    final Map<String, String> balances = ref.watch(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.transfer),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          Spaces.large,
          Spaces.none,
          Spaces.large,
          Spaces.large,
        ),
        children: [
          Text(
            loc.transfer_screen_message,
            style: context.titleMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spaces.extraLarge),
          FormBuilder(
            key: _transferFormKey,
            onChanged: _updateEstimatedFee,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.amount.capitalize(), style: context.titleMedium),
                const SizedBox(height: Spaces.small),
                FormBuilderTextField(
                  name: 'amount',
                  focusNode: _focusNodeAmount,
                  style: context.headlineLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  autocorrect: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: context.textInputDecoration.copyWith(
                    labelText: AppResources.zeroBalance,
                    labelStyle: context.headlineLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(Spaces.small),
                      child: TextButton(
                        onPressed: () => _transferFormKey
                            .currentState
                            ?.fields['amount']
                            ?.didChange(_selectedAssetBalance),
                        child: Text(loc.max),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    // workaround to reset the error message when the user modifies the field
                    final hasError = _transferFormKey
                        .currentState
                        ?.fields['amount']
                        ?.hasError;
                    if (hasError ?? false) {
                      _transferFormKey.currentState?.fields['amount']?.reset();
                    }
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                    FormBuilderValidators.numeric(
                      errorText: loc.must_be_numeric_error,
                    ),
                    (val) {
                      if (val != null) {
                        final amount = double.tryParse(val);
                        if (amount == null || amount == 0) {
                          return loc.invalid_amount_error;
                        }
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: Spaces.large),
                Text(loc.asset, style: context.titleMedium),
                const SizedBox(height: Spaces.small),
                GenericFormBuilderDropdown<String>(
                  name: 'assets',
                  enabled: balances.isNotEmpty && assets.isNotEmpty,
                  initialValue: balances.isNotEmpty && assets.isNotEmpty
                      ? balances.entries
                            .where((balance) => assets.containsKey(balance.key))
                            .firstOrNull
                            ?.key
                      : null,
                  items: balances.entries
                      .where((balance) => assets.containsKey(balance.key))
                      .map(
                        (balance) => AssetDropdownMenuItem.fromMapEntry(
                          balance,
                          assets[balance.key]!,
                        ),
                      )
                      .toList(),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                  ]),
                  onChanged: (val) {
                    if (val != null && balances.containsKey(val)) {
                      setState(() {
                        _selectedAssetBalance = balances[val]!;
                      });
                    }
                    // workaround to reset the error message when the user modifies the field
                    final hasError = _transferFormKey
                        .currentState
                        ?.fields['assets']
                        ?.hasError;
                    if (hasError ?? false) {
                      _transferFormKey.currentState?.fields['assets']?.reset();
                    }
                  },
                ),
                const SizedBox(height: Spaces.large),
                Text(loc.destination, style: context.titleMedium),
                const SizedBox(height: Spaces.small),
                FormBuilderTextField(
                  name: 'address',
                  focusNode: _focusNodeAddress,
                  style: context.bodyMedium,
                  autocorrect: false,
                  keyboardType: TextInputType.text,
                  decoration: context.textInputDecoration.copyWith(
                    labelText: loc.receiver_address,
                    suffixIcon: IconButton(
                      tooltip: loc.select_from_address_book,
                      onPressed: _onAddressBookClicked,
                      icon: Icon(Icons.my_library_books_outlined, size: 18),
                    ),
                  ),
                  onChanged: (value) {
                    // workaround to reset the error message when the user modifies the field
                    final hasError = _transferFormKey
                        .currentState
                        ?.fields['address']
                        ?.hasError;
                    if (hasError ?? false) {
                      _transferFormKey.currentState?.fields['address']?.reset();
                    }
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                    _addressValidator,
                  ]),
                ),
                const SizedBox(height: Spaces.extraLarge),
                Row(
                  children: [
                    Text(loc.estimated_fee, style: context.titleMedium),
                    const SizedBox(width: Spaces.small),
                    Text(
                      '$_estimatedFee ${getXelisTicker(network)}',
                      style: context.titleMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spaces.large),
                Text(loc.boost_fees_title, style: context.titleMedium),
                Text(
                  loc.boost_fees_message,
                  style: context.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
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
                      child: Text('x$value', style: context.bodyLarge),
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

  Future<void> _reviewTransfer() async {
    // Update selected asset from controller
    final selectedAsset = _assetController.value;
    if (selectedAsset != null) {
      _selectedAsset = selectedAsset.key;
      final Map<String, String> balances = ref.read(
        walletStateProvider.select((value) => value.trackedBalances),
      );
      _selectedAssetBalance =
          balances[_selectedAsset] ?? AppResources.zeroBalance;
    }

    // Ensure an asset is selected
    if (_selectedAsset == null) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.field_required_error);
      return;
    }

    if (_selectedAssetBalance == AppResources.zeroBalance) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.no_balance_to_transfer);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final amount = _amountController.text.trim();
      final address = _addressController.text.trim();
      final loc = ref.read(appLocalizationsProvider);

      context.loaderOverlay.show();

      try {
        (TransactionSummary?, String?) record;
        if (amount == _selectedAssetBalance) {
          record = await ref
              .read(walletStateProvider.notifier)
              .sendAll(destination: address, asset: _selectedAsset!);
        } else {
          record = await ref
              .read(walletStateProvider.notifier)
              .send(
                amount: double.parse(amount),
                destination: address,
                asset: _selectedAsset!,
              );
        }

        if (record.$2 != null) {
          // MULTISIG: hash to sign → legacy dialog
          ref
              .read(transactionReviewProvider.notifier)
              .signaturePending(record.$2!);

          if (mounted) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return const TransactionDialog();
              },
            );
          }
        } else if (record.$1 != null) {
          // SIMPLE TRANSFER: use new forui review dialog
          final txSummary = record.$1!;

          // Populate review provider
          ref
              .read(transactionReviewProvider.notifier)
              .setSingleTransferTransaction(txSummary);

          // Read back the mapped state (SingleTransferTransaction) from provider
          final state = ref.read(transactionReviewProvider);
          if (state is SingleTransferTransaction && mounted) {
            showFDialog<void>(
              context: context,
              builder: (dialogContext, style, animation) {
                return TransferReviewContentWidget(
                  style,
                  animation,
                  transaction: state,
                  onConfirm: () async {
                    await _broadcastTransfer();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  onCancel: () {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                );
              },
            );
          }
        } else {
          // Nothing returned → just bail with a warning
          ref
              .read(toastProvider.notifier)
              .showError(description: loc.oups);
        }
      } catch (e) {
        // Make sure we at least tell the user something went wrong
        ref
            .read(toastProvider.notifier)
            .showError(description: e.toString());
      } finally {
        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
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
      // final multiplier =
      //     _transferFormKey.currentState?.fields['fee']?.value as double;

      ref
          .read(walletStateProvider.notifier)
          .estimateFees(
            amount: double.parse(amount),
            destination: address.trim(),
            asset: asset,
            // feeMultiplier: multiplier,
          )
          .then((value) {
            setState(() {
              final estimatedFee = double.parse(value);
              _isFeeEstimated = estimatedFee > 0;
              _estimatedFee = estimatedFee.toStringAsFixed(
                AppResources.xelisDecimals,
              );
            });
          });
    } else {
      setState(() {
        _isFeeEstimated = false;
        _estimatedFee = AppResources.zeroBalance;
      });
    }
  }

  String? _addressValidator(String? value) {
    final network = ref.read(settingsProvider.select((state) => state.network));
    if (value != null &&
        !isAddressValid(strAddress: value.trim(), network: network)) {
      return ref.read(appLocalizationsProvider).invalid_address_format_error;
    }
    return null;
  }

  Future<void> _onAddressBookClicked() async {
    final address = await showDialog<String>(
      context: context,
      builder: (context) => const SelectAddressDialog(),
    );
    if (address != null) {
      _transferFormKey.currentState?.fields['address']?.didChange(address);
    }
  }
}
