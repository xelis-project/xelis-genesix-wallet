import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/select_address_dialog.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:recase/recase.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

// import 'package:genesix/features/wallet/domain/transaction_review_state.dart';

const _automaticFeeBasisPoints = XelisWalletFeePolicy.basisPointsScale;
const _fastFeeBasisPoints = 15000;
const _fastestFeeBasisPoints = 20000;

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.recipientContactId});

  /// Address-book entry ID resolved locally after navigation.
  ///
  /// Passing the complete destination through GoRouter would persist it in
  /// route state and expose it to debug route observers.
  final String? recipientContactId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  late final FSelectController<MapEntry<String, XelisWalletAssetMetadata>>
  _assetController;
  late final FSelectController<int> _boostFeeController;

  String? _selectedAsset;
  BigInt _selectedAssetBalance = BigInt.zero;
  BigInt _estimatedFeeAtomic = BigInt.zero;
  int _feeMultiplierBasisPoints = _automaticFeeBasisPoints;
  var _feeEstimateGeneration = 0;
  var _isReviewing = false;
  var _addressInputWasEdited = false;

  void _onFormInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final Map<String, BigInt> balances = ref.read(
      walletRuntimeProvider.select((value) => value.trackedBalances),
    );
    final Map<String, XelisWalletAssetMetadata> assets = ref.read(
      walletRuntimeProvider.select((value) => value.knownAssets),
    );

    // Get first valid balance
    final firstValidBalance = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .firstOrNull;

    MapEntry<String, XelisWalletAssetMetadata>? initialAssetEntry;
    if (firstValidBalance != null) {
      initialAssetEntry = MapEntry(
        firstValidBalance.key,
        assets[firstValidBalance.key]!,
      );
      _selectedAsset = firstValidBalance.key;
      _selectedAssetBalance = firstValidBalance.value;
    }

    _assetController =
        FSelectController<MapEntry<String, XelisWalletAssetMetadata>>(
          value: initialAssetEntry,
        );

    _boostFeeController = FSelectController<int>(
      value: _automaticFeeBasisPoints,
    );
    _feeMultiplierBasisPoints =
        _boostFeeController.value ?? _automaticFeeBasisPoints;

    ref.listenManual<bool>(
      walletRuntimeProvider.select((state) => state.multisigState != null),
      (previous, next) {
        if (previous != next) {
          _updateEstimatedFee();
        }
      },
    );

    _amountController.addListener(_onFormInputChanged);
    _addressController.addListener(_onFormInputChanged);
    unawaited(_prefillRecipientFromAddressBook());
  }

  @override
  void dispose() {
    _feeEstimateGeneration++;
    _amountController.removeListener(_onFormInputChanged);
    _addressController.removeListener(_onFormInputChanged);
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
    const inputHeight = 40.0;

    final Map<String, BigInt> balances = ref.watch(
      walletRuntimeProvider.select((value) => value.trackedBalances),
    );
    final Map<String, XelisWalletAssetMetadata> assets = ref.watch(
      walletRuntimeProvider.select((value) => value.knownAssets),
    );
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final isMultisig = ref.watch(
      walletRuntimeProvider.select((state) => state.multisigState != null),
    );

    final validAssets = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .toList();

    return PopScope(
      canPop: !_isReviewing,
      child: FScaffold(
        header: Padding(
          padding: const EdgeInsets.only(top: Spaces.medium),
          child: FHeader.nested(
            prefixes: [
              Padding(
                padding: const EdgeInsets.all(Spaces.small),
                child: FHeaderAction.back(
                  onPress: _isReviewing ? null : _onBackPressed,
                ),
              ),
            ],
            title: Text(loc.transfer),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FadedScroll(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: Spaces.medium,
                //vertical: Spaces.large,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Asset Selection
                    FSelect<
                      MapEntry<String, XelisWalletAssetMetadata>
                    >.searchBuilder(
                      label: Text(loc.asset.titleCase),
                      hint: validAssets.isEmpty
                          ? loc.no_balance_to_transfer
                          : loc.select_asset,
                      control: .managed(
                        controller: _assetController,
                        onChange: (assetEntry) {
                          setState(() {
                            _selectedAsset = assetEntry?.key;
                            _selectedAssetBalance = assetEntry == null
                                ? BigInt.zero
                                : balances[assetEntry.key] ?? BigInt.zero;
                          });
                          _updateEstimatedFee();
                        },
                      ),
                      enabled: validAssets.isNotEmpty,
                      format: (assetEntry) {
                        final balance = balances[assetEntry.key] ?? BigInt.zero;
                        final formattedBalance = formatCoin(
                          balance,
                          assetEntry.value.decimals,
                          assetEntry.value.ticker,
                        );
                        return '${assetEntry.value.name} ($formattedBalance)';
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
                              balances[assetEntry.key] ?? BigInt.zero;
                          return FSelectItem<
                            MapEntry<String, XelisWalletAssetMetadata>
                          >(
                            title: Text(
                              '${assetEntry.value.name} (${truncateText(assetEntry.key)})',
                            ),
                            subtitle: Text(
                              formatCoin(
                                balance,
                                assetEntry.value.decimals,
                                assetEntry.value.ticker,
                              ),
                            ),
                            value: assetEntry,
                          );
                        }).toList();
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
                            control: .managed(
                              controller: _amountController,
                              onChange: (_) => _updateEstimatedFee(),
                            ),
                            label: Text(loc.amount.titleCase),
                            hint: AppResources.zeroBalance,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return loc.field_required_error;
                              }
                              final selectedAsset = _assetController.value;
                              if (selectedAsset == null) {
                                return loc.field_required_error;
                              }
                              try {
                                parseAtomicAmount(
                                  value.trim(),
                                  selectedAsset.value.decimals,
                                );
                              } on FormatException {
                                return loc.invalid_amount_error;
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 20),
                          child: SizedBox(
                            height: inputHeight,
                            child: FButton(
                              variant: .outline,
                              onPress: () {
                                final selectedAsset = _assetController.value;
                                if (selectedAsset != null) {
                                  _selectedAsset = selectedAsset.key;
                                  _selectedAssetBalance =
                                      balances[_selectedAsset] ?? BigInt.zero;
                                }
                                if (selectedAsset != null) {
                                  _amountController.text = formatAtomicAmount(
                                    _selectedAssetBalance,
                                    selectedAsset.value.decimals,
                                  );
                                }
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
                                control: .managed(
                                  controller: _addressController,
                                  onChange: (_) {
                                    _addressInputWasEdited = true;
                                    _updateEstimatedFee();
                                  },
                                ),
                                label: Text(loc.destination.titleCase),
                                hint: loc.receiver_address,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return loc.field_required_error;
                                  }
                                  if (!XelisWalletFlutter.isAddressValid(
                                    address: value.trim(),
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
                                    style: context.theme.typography.body.md,
                                  );
                                },
                                child: FButton.icon(
                                  semanticsTooltip: loc.address_book,
                                  variant: .outline,
                                  onPress: _onAddressBookClicked,
                                  child: const Icon(
                                    FLucideIcons.bookUser,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Spaces.large),

                    // Fee Information Section
                    AppCard(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spaces.small,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.estimated_fee,
                                style: context.theme.typography.body.sm
                                    .copyWith(
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                              ),
                              const SizedBox(width: Spaces.extraSmall),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${formatAtomicAmount(_estimatedFeeAtomic, AppResources.xelisDecimals)} '
                                    '${getXelisTicker(network)}',
                                    style: context.theme.typography.body.md
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isMultisig) ...[
                            FDivider(
                              style: .delta(
                                padding: .value(
                                  .symmetric(vertical: Spaces.small),
                                ),
                                color: context.theme.colors.primary,
                                width: 1,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: Spaces.extraSmall,
                              children: [
                                Text(
                                  loc.boost_fees_title,
                                  style: context.theme.typography.body.sm
                                      .copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  loc.boost_fees_message,
                                  style: context.theme.typography.body.xs
                                      .copyWith(
                                        color: context
                                            .theme
                                            .colors
                                            .mutedForeground,
                                      ),
                                ),
                                const SizedBox(height: Spaces.extraSmall),
                                FSelect<int>.rich(
                                  control: .managed(
                                    controller: _boostFeeController,
                                    onChange: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _feeMultiplierBasisPoints = value;
                                        });
                                        _updateEstimatedFee();
                                      }
                                    },
                                  ),
                                  format: _formatFeePolicy,
                                  children: const [
                                    FSelectItem(
                                      value: _automaticFeeBasisPoints,
                                      title: Text('Normal'),
                                      subtitle: Text('1x fee'),
                                    ),
                                    FSelectItem(
                                      value: _fastFeeBasisPoints,
                                      title: Text('Fast'),
                                      subtitle: Text('1.5x fee'),
                                    ),
                                    FSelectItem(
                                      value: _fastestFeeBasisPoints,
                                      title: Text('Fastest'),
                                      subtitle: Text('2x fee'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: Spaces.large),

                    // Review Button
                    AsyncFButton(
                      isLoading: _isReviewing,
                      onDisabledPress: _handleDisabledReviewPress,
                      onPress:
                          validAssets.isEmpty ||
                              _assetController.value == null ||
                              _selectedAsset == null ||
                              _addressController.text.trim().isEmpty ||
                              _amountController.text.trim().isEmpty
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
    final address = await showAppDialog<String>(
      context: context,
      builder: (dialogContext, _, animation) {
        return SelectAddressDialog(animation);
      },
    );

    if (address != null) {
      setState(() {
        _addressController.text = address;
      });
      _updateEstimatedFee();
    }
  }

  Future<void> _prefillRecipientFromAddressBook() async {
    final contactId = widget.recipientContactId;
    if (contactId == null) return;

    try {
      final contact = await ref
          .read(addressBookProvider.notifier)
          .getById(contactId);
      if (!mounted || _addressInputWasEdited) return;

      if (contact == null) {
        ref
            .read(toastProvider.notifier)
            .showError(
              description: ref.read(appLocalizationsProvider).contact_not_found,
            );
        return;
      }

      _addressController.text = contact.destination.address;
      _updateEstimatedFee();
    } catch (error, stackTrace) {
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.address_book.recipient.resolve',
        applicationCode: 'wallet_address_book_recipient_resolve_failed',
      );
      if (!mounted || _addressInputWasEdited) return;
      ref.read(toastProvider.notifier).showFailure(failure: failure);
    }
  }

  void _onBackPressed() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AuthAppScreen.home.toPath);
  }

  Future<void> _updateEstimatedFee() async {
    final generation = ++_feeEstimateGeneration;
    final selectedAsset = _assetController.value;
    if (selectedAsset != null) {
      _selectedAsset = selectedAsset.key;
    }

    final boostValue = _boostFeeController.value;
    if (boostValue != null) {
      _feeMultiplierBasisPoints = boostValue;
    }

    final address = _addressController.text.trim();
    BigInt? amountAtomic;
    if (selectedAsset != null) {
      try {
        amountAtomic = parseAtomicAmount(
          _amountController.text.trim(),
          selectedAsset.value.decimals,
        );
      } on FormatException {
        amountAtomic = null;
      }
    }
    if (address.isEmpty || amountAtomic == null || _selectedAsset == null) {
      _setEstimatedFee(generation, BigInt.zero);
      return;
    }

    try {
      final estimatedFee = await ref
          .read(walletCommandsProvider)
          .estimateFees(
            amountAtomic: amountAtomic,
            destination: address,
            asset: _selectedAsset!,
            feePolicy: _activeFeePolicy,
          );
      _setEstimatedFee(generation, estimatedFee);
    } catch (_) {
      _setEstimatedFee(generation, BigInt.zero);
    }
  }

  void _setEstimatedFee(int generation, BigInt feeAtomic) {
    if (!mounted || generation != _feeEstimateGeneration) return;
    setState(() => _estimatedFeeAtomic = feeAtomic);
  }

  XelisWalletFeePolicy get _activeFeePolicy {
    if (ref.read(walletRuntimeProvider).multisigState != null ||
        _feeMultiplierBasisPoints == _automaticFeeBasisPoints) {
      return XelisWalletFeePolicy.automatic;
    }
    return XelisWalletFeePolicy.multiplier(
      basisPoints: _feeMultiplierBasisPoints,
    );
  }

  void _handleDisabledReviewPress() {
    if (_isReviewing) return;

    final loc = ref.read(appLocalizationsProvider);
    final runtime = ref.read(walletRuntimeProvider);
    final hasValidAsset = runtime.trackedBalances.keys.any(
      runtime.knownAssets.containsKey,
    );
    if (!hasValidAsset) {
      ref
          .read(toastProvider.notifier)
          .showWarning(title: loc.no_balance_to_transfer);
      return;
    }
    if (_assetController.value == null || _selectedAsset == null) {
      ref.read(toastProvider.notifier).showWarning(title: loc.select_asset);
      return;
    }

    _formKey.currentState?.validate();
  }

  void _reviewTransfer() async {
    if (_isReviewing) return;

    // Update selected asset from controller
    final selectedAsset = _assetController.value;
    _selectedAsset = selectedAsset?.key;
    final Map<String, BigInt> balances = ref.read(
      walletRuntimeProvider.select((value) => value.trackedBalances),
    );
    _selectedAssetBalance = selectedAsset == null
        ? BigInt.zero
        : balances[selectedAsset.key] ?? BigInt.zero;

    // Ensure an asset is selected
    if (_selectedAsset == null) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.field_required_error);
      return;
    }
    final selectedAssetMetadata = ref
        .read(walletRuntimeProvider)
        .knownAssets[_selectedAsset];
    if (selectedAssetMetadata == null) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.field_required_error);
      return;
    }

    if (_selectedAssetBalance == BigInt.zero) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.no_balance_to_transfer);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final amountAtomic = parseAtomicAmount(
        _amountController.text.trim(),
        selectedAssetMetadata.decimals,
      );
      final address = _addressController.text.trim();
      final commands = ref.read(walletCommandsProvider);
      final sessionIdentity = ref.read(activeWalletRepositoryProvider);
      if (sessionIdentity == null) return;
      final feePolicy = _activeFeePolicy;

      setState(() => _isReviewing = true);

      late (XelisWalletPreparedTransaction?, XelisWalletMultisigSigningRequest?)
      record;
      try {
        if (amountAtomic == _selectedAssetBalance) {
          record = await commands.sendAll(
            destination: address,
            asset: _selectedAsset!,
            feePolicy: feePolicy,
          );
        } else {
          record = await commands.send(
            amountAtomic: amountAtomic,
            destination: address,
            asset: _selectedAsset!,
            feePolicy: feePolicy,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isReviewing = false);
        }
      }

      if (!mounted) {
        if (record.$2 case final request?) {
          await commands.cancelPendingMultisigRequest(
            request: request,
            sessionIdentity: sessionIdentity,
          );
        } else if (record.$1 case final transaction?) {
          await commands.cancelPreparedTransaction(
            transaction: transaction,
            sessionIdentity: sessionIdentity,
          );
        }
        return;
      }

      if (!identical(
        ref.read(activeWalletRepositoryProvider),
        sessionIdentity,
      )) {
        if (record.$2 case final request?) {
          await commands.cancelPendingMultisigRequest(
            request: request,
            sessionIdentity: sessionIdentity,
          );
        } else if (record.$1 case final transaction?) {
          await commands.cancelPreparedTransaction(
            transaction: transaction,
            sessionIdentity: sessionIdentity,
          );
        }
        return;
      }

      if (record.$2 != null) {
        ref
            .read(transactionReviewProvider.notifier)
            .signaturePending(record.$2!, sessionIdentity: sessionIdentity);

        if (mounted) {
          await context.push(AuthAppScreen.transactionReview.toPath);
        }
      } else if (record.$1 != null) {
        final prepared = record.$1!;

        ref
            .read(transactionReviewProvider.notifier)
            .setPreparedSingleTransferTransaction(
              prepared,
              sessionIdentity: sessionIdentity,
            );

        if (mounted) {
          await context.push(AuthAppScreen.transactionReview.toPath);
        }
      }
    }
  }
}

String _formatFeePolicy(int basisPoints) => switch (basisPoints) {
  _automaticFeeBasisPoints => 'Normal (1x)',
  _fastFeeBasisPoints => 'Fast (1.5x)',
  _fastestFeeBasisPoints => 'Fastest (2x)',
  _ => 'Normal (1x)',
};
