import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/select_address_dialog.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transaction_dialog_old.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transfer/transfer_review_content.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transaction_review_dialog_new.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:recase/recase.dart';
import 'package:go_router/go_router.dart';

class TransferScreenNew extends ConsumerStatefulWidget {
  const TransferScreenNew({super.key, this.recipientAddress});

  final String? recipientAddress;

  @override
  ConsumerState<TransferScreenNew> createState() => _TransferScreenNewState();
}

class _TransferScreenNewState extends ConsumerState<TransferScreenNew>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  late final _assetController = FSelectController<MapEntry<String, AssetData>>(
    vsync: this,
  );
  late final _boostFeeController = FSelectController<double>(vsync: this);

  String? _selectedAsset;
  String _selectedAssetBalance = AppResources.zeroBalance;
  String _estimatedFee = AppResources.zeroBalance;
  String _baseFee = AppResources.zeroBalance;
  double _boostMultiplier = 1.0;

  @override
  void initState() {
    super.initState();

    final Map<String, String> balances = ref.read(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.read(
      walletStateProvider.select((value) => value.knownAssets),
    );

    // Get first valid balance
    final firstValidBalance = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .firstOrNull;

    if (firstValidBalance != null) {
      _selectedAsset = firstValidBalance.key;
      _selectedAssetBalance = firstValidBalance.value;
      final assetEntry = MapEntry(
        firstValidBalance.key,
        assets[firstValidBalance.key]!,
      );
      _assetController.value = assetEntry;
    }

    // Initialize boost fee to normal (1.0x)
    _boostFeeController.value = 1.0;

    // Pre-fill address if provided
    if (widget.recipientAddress != null) {
      _addressController.text = widget.recipientAddress!;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _amountController.dispose();
    _addressController.dispose();
    _assetController.dispose();
    _boostFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final inputHeight = 40.0;

    final Map<String, String> balances = ref.watch(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );

    final validAssets = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .toList();

    return FScaffold(
      header: Padding(
        padding: const EdgeInsets.only(top: Spaces.medium),
        child: FHeader.nested(
          prefixes: [
            Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: FHeaderAction.back(
                onPress: () => context.pop(),
              ),
            ),
          ],
          title: Text(loc.transfer),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FadedScroll(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: Spaces.extraLarge * 1.5,
                vertical: Spaces.large,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Asset Selection
                    FSelect<MapEntry<String, AssetData>>.searchBuilder(
                      label: Text(loc.asset.titleCase),
                      hint: validAssets.isEmpty
                          ? loc.no_balance_to_transfer
                          : loc.select_asset,
                      controller: _assetController,
                      enabled: validAssets.isNotEmpty,
                      format: (assetEntry) {
                        final balance =
                            balances[assetEntry.key] ??
                            AppResources.zeroBalance;
                        return '${assetEntry.value.name} (${balance} ${assetEntry.value.ticker})';
                      },
                      filter: (query) {
                        final availableAssets = validAssets
                            .map(
                              (balance) =>
                                  MapEntry(balance.key, assets[balance.key]!),
                            )
                            .toList();

                        if (query.isEmpty) {
                          return availableAssets;
                        }

                        return availableAssets
                            .where(
                              (assetEntry) =>
                                  assetEntry.value.name.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ) ||
                                  assetEntry.value.ticker
                                      .toLowerCase()
                                      .contains(query.toLowerCase()),
                            )
                            .toList();
                      },
                      contentBuilder: (context, style, data) {
                        return data.map((assetEntry) {
                          final balance =
                              balances[assetEntry.key] ??
                              AppResources.zeroBalance;
                          return FSelectItem<MapEntry<String, AssetData>>(
                            title: Text(assetEntry.value.name),
                            subtitle: Text(
                              '$balance ${assetEntry.value.ticker}',
                            ),
                            value: assetEntry,
                          );
                        }).toList();
                      },
                      onChange: (assetEntry) {
                        if (assetEntry != null) {
                          setState(() {
                            _selectedAsset = assetEntry.key;
                            _selectedAssetBalance =
                                balances[_selectedAsset] ??
                                    AppResources.zeroBalance;
                          });
                          _updateEstimatedFee();
                        }
                      },
                      validator: (value) =>
                          value == null ? loc.field_required_error : null,
                    ),
                    const SizedBox(height: Spaces.medium),

                    // Amount Input with Max Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FTextFormField(
                            controller: _amountController,
                            label: Text(loc.amount.titleCase),
                            hint: AppResources.zeroBalance,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return loc.field_required_error;
                              }
                              final amount = double.tryParse(value);
                              if (amount == null) {
                                return loc.must_be_numeric_error;
                              }
                              if (amount <= 0) {
                                return loc.invalid_amount_error;
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            top: 20,
                          ),
                          child: SizedBox(
                            height: inputHeight,
                            child: FButton(
                              style: FButtonStyle.outline(),
                              onPress: () {
                                final selectedAsset = _assetController.value;
                                if (selectedAsset != null) {
                                  _selectedAsset = selectedAsset.key;
                                  _selectedAssetBalance =
                                      balances[_selectedAsset] ??
                                      AppResources.zeroBalance;
                                }
                                _amountController.text = _selectedAssetBalance;
                                _updateEstimatedFee();
                              },
                              child: Text(loc.max),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spaces.medium),

                    // Destination Address with Contact Suggestions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FTextFormField(
                                controller: _addressController,
                                label: Text(loc.destination.titleCase),
                                hint: loc.receiver_address,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return loc.field_required_error;
                                  }
                                  if (!isAddressValid(
                                    strAddress: value.trim(),
                                    network: network,
                                  )) {
                                    return loc.invalid_address_format_error;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: Spaces.medium),
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: FTooltip(
                                tipBuilder: (context, controller) {
                                  return Text(
                                    loc.address_book,
                                    style: context.theme.typography.base,
                                  );
                                },
                                child: FButton.icon(
                                  style: FButtonStyle.outline(),
                                  onPress: _onAddressBookClicked,
                                  child: const Icon(FIcons.bookUser, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Spaces.large),

                    // Fee Information Section
                    FCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spaces.small,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.estimated_fee,
                                style: context.theme.typography.sm.copyWith(
                                  color: context.theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(width: Spaces.extraSmall),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _boostMultiplier != 1.0
                                        ? '$_baseFee × ${_boostMultiplier}x = $_estimatedFee ${getXelisTicker(network)}'
                                        : '$_estimatedFee ${getXelisTicker(network)}',
                                    style: context.theme.typography.base
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          FDivider(
                            style: FDividerStyle(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spaces.small,
                              ),
                              color: FTheme.of(context).colors.primary,
                              width: 1,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: Spaces.extraSmall,
                            children: [
                              Text(
                                loc.boost_fees_title,
                                style: context.theme.typography.sm.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                loc.boost_fees_message,
                                style: context.theme.typography.xs.copyWith(
                                  color: context.theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: Spaces.extraSmall),
                              FSelect<double>.rich(
                                controller: _boostFeeController,
                                format: (value) {
                                  if (value == 1.0) return 'Normal (1x)';
                                  if (value == 1.5) return 'Fast (1.5x)';
                                  if (value == 2.0) return 'Fastest (2x)';
                                  return 'Normal (1x)';
                                },
                                children: const [
                                  FSelectItem(
                                    value: 1.0,
                                    title: Text('Normal'),
                                    subtitle: Text('1x fee'),
                                  ),
                                  FSelectItem(
                                    value: 1.5,
                                    title: Text('Fast'),
                                    subtitle: Text('1.5x fee'),
                                  ),
                                  FSelectItem(
                                    value: 2.0,
                                    title: Text('Fastest'),
                                    subtitle: Text('2x fee'),
                                  ),
                                ],
                                onChange: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _boostMultiplier = value;
                                    });
                                    _updateEstimatedFee();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Spaces.large),

                    // Review Button
                    FButton(
                      style: FButtonStyle.primary(),
                      onPress: validAssets.isEmpty ||
                              _selectedAsset == null ||
                              _addressController.text.trim().isEmpty
                          ? null
                          : _reviewTransfer,
                      child: Text(loc.review_send),
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

  Future<void> _onAddressBookClicked() async {
    final address = await showFDialog<String>(
      context: context,
      builder: (dialogContext, style, animation) {
        return SelectAddressDialog(style, animation);
      },
    );

    if (address != null) {
      setState(() {
        _addressController.text = address;
      });
      _updateEstimatedFee();
    }
  }

  void _updateEstimatedFee() {
    final selectedAsset = _assetController.value;
    if (selectedAsset != null) {
      _selectedAsset = selectedAsset.key;
    }

    // Update boost multiplier
    final boostValue = _boostFeeController.value;
    if (boostValue != null) {
      _boostMultiplier = boostValue;
    }

    final amount = double.tryParse(_amountController.text);
    final address = _addressController.text.trim();

    if (address.isNotEmpty && _selectedAsset != null) {
      ref
          .read(walletStateProvider.notifier)
          .estimateFees(
            amount: amount ?? 0.0,
            destination: address,
            asset: _selectedAsset!,
          )
          .then((value) {
        if (mounted) {
          setState(() {
            final baseFee = double.parse(value);
            _baseFee =
                baseFee.toStringAsFixed(AppResources.xelisDecimals);
            final boostedFee = baseFee * _boostMultiplier;
            _estimatedFee = boostedFee.toStringAsFixed(
              AppResources.xelisDecimals,
            );
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _baseFee = AppResources.zeroBalance;
            _estimatedFee = AppResources.zeroBalance;
          });
        }
      });
    } else {
      setState(() {
        _baseFee = AppResources.zeroBalance;
        _estimatedFee = AppResources.zeroBalance;
      });
    }
  }

  Future<void> _broadcastTransfer() async {
    final loc = ref.read(appLocalizationsProvider);

    try {
      context.loaderOverlay.show();

      final transactionReview = ref.read(transactionReviewProvider);

      if (transactionReview is SingleTransferTransaction) {
        await ref
            .read(walletStateProvider.notifier)
            .broadcastTx(hash: transactionReview.txHash);

        ref.read(transactionReviewProvider.notifier).broadcast();

        ref
            .read(toastProvider.notifier)
            .showEvent(description: loc.transaction_broadcast_message);
      } else {
        ref.read(toastProvider.notifier).showError(
              description: 'Unexpected transaction type for broadcast.',
            );
      }
    } catch (e) {
      ref
          .read(toastProvider.notifier)
          .showError(description: e.toString());
    } finally {
      if (context.mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  void _reviewTransfer() async {
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

      context.loaderOverlay.show();

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
      }  else if (record.$1 != null) {
        // SIMPLE TRANSFER: set review state and show the new review dialog
        final txSummary = record.$1!;

        ref
            .read(transactionReviewProvider.notifier)
            .setSingleTransferTransaction(txSummary);

        if (mounted) {
          await showFDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext, style, animation) {
              return TransactionReviewDialogNew(style, animation);
            },
          );
        }
      } else {
        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
        return;
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
