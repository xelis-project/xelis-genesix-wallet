import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

class BurnScreen extends ConsumerStatefulWidget {
  const BurnScreen({super.key});

  @override
  ConsumerState<BurnScreen> createState() => _BurnScreenState();
}

class _BurnScreenState extends ConsumerState<BurnScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late final FSelectController<MapEntry<String, XelisWalletAssetMetadata>>
  _assetController;

  String? _selectedAsset;
  BigInt _selectedAssetBalance = BigInt.zero;
  var _isReviewing = false;

  @override
  void initState() {
    super.initState();

    final Map<String, BigInt> balances = ref.read(
      walletRuntimeProvider.select((value) => value.trackedBalances),
    );
    final Map<String, XelisWalletAssetMetadata> assets = ref.read(
      walletRuntimeProvider.select((value) => value.knownAssets),
    );

    final firstValidBalance = balances.entries
        .where((entry) => assets.containsKey(entry.key))
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _assetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final Map<String, BigInt> balances = ref.watch(
      walletRuntimeProvider.select((value) => value.trackedBalances),
    );
    final Map<String, XelisWalletAssetMetadata> assets = ref.watch(
      walletRuntimeProvider.select((value) => value.knownAssets),
    );

    final validAssets = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .toList();

    const inputHeight = 40.0;

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
                  onPress: _isReviewing ? null : () => context.pop(),
                ),
              ),
            ],
            title: Text(loc.burn),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Spaces.extraLarge * 1.5,
                vertical: Spaces.large,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FAlert(
                    title: Text(loc.warning),
                    subtitle: Text(
                      loc.burn_screen_warning_message,
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.destructiveForeground,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spaces.extraLarge),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Amount + Max
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FTextFormField(
                                control: .managed(
                                  controller: _amountController,
                                ),
                                label: Text(loc.amount.capitalize()),
                                hint: AppResources.zeroBalance,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
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
                            const SizedBox(width: Spaces.small),
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: SizedBox(
                                height: inputHeight,
                                child: FButton(
                                  variant: .outline,
                                  onPress: () {
                                    final selected = _assetController.value;
                                    if (selected != null) {
                                      _selectedAsset = selected.key;
                                      _selectedAssetBalance =
                                          balances[_selectedAsset] ??
                                          BigInt.zero;
                                    }
                                    if (selected != null) {
                                      _amountController.text =
                                          formatAtomicAmount(
                                            _selectedAssetBalance,
                                            selected.value.decimals,
                                          );
                                    }
                                  },
                                  child: Text(loc.max),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: Spaces.large),
                        Text(
                          loc.asset.capitalize(),
                          style: context.theme.typography.body.sm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: Spaces.small),

                        // Asset select
                        FSelect<
                          MapEntry<String, XelisWalletAssetMetadata>
                        >.rich(
                          control: .managed(
                            controller: _assetController,
                            onChange: (entry) {
                              if (entry != null) {
                                setState(() {
                                  _selectedAsset = entry.key;
                                  _selectedAssetBalance =
                                      balances[_selectedAsset] ?? BigInt.zero;
                                });
                              }
                            },
                          ),
                          enabled: validAssets.isNotEmpty,
                          hint: validAssets.isEmpty
                              ? loc.no_balance_to_burn
                              : loc.select_asset,
                          format: (entry) => entry.value.name,
                          children: validAssets.map((entry) {
                            final assetData = assets[entry.key]!;
                            final balance = balances[entry.key] ?? BigInt.zero;
                            return FSelectItem<
                              MapEntry<String, XelisWalletAssetMetadata>
                            >(
                              value: MapEntry(entry.key, assetData),
                              title: Text(assetData.name),
                              subtitle: Text(
                                formatCoin(
                                  balance,
                                  assetData.decimals,
                                  assetData.ticker,
                                ),
                              ),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null) {
                              return loc.field_required_error;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Spaces.extraLarge),

                  // Review button centered on wide screens
                  Row(
                    children: [
                      if (context.isWideLayout) const Spacer(),
                      Expanded(
                        child: AsyncFButton(
                          isLoading: _isReviewing,
                          onPress: validAssets.isEmpty ? null : _reviewBurn,
                          child: Text(loc.review_burn),
                        ),
                      ),
                      if (context.isWideLayout) const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reviewBurn() async {
    if (_isReviewing) return;

    final loc = ref.read(appLocalizationsProvider);

    // Ensure asset is in sync with controller
    final selectedEntry = _assetController.value;
    if (selectedEntry == null) {
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.field_required_error);
      return;
    }

    _selectedAsset = selectedEntry.key;
    _selectedAssetBalance =
        ref.read(walletRuntimeProvider).trackedBalances[_selectedAsset] ??
        BigInt.zero;

    if (_selectedAssetBalance == BigInt.zero) {
      ref
          .read(toastProvider.notifier)
          .showWarning(title: loc.no_balance_to_burn);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amountAtomic = parseAtomicAmount(
      _amountController.text.trim(),
      selectedEntry.value.decimals,
    );
    final asset = _selectedAsset!;
    final commands = ref.read(walletCommandsProvider);
    final sessionIdentity = ref.read(activeWalletRepositoryProvider);
    if (sessionIdentity == null) return;
    const feePolicy = XelisWalletFeePolicy.automatic;

    setState(() => _isReviewing = true);

    late (XelisWalletPreparedTransaction?, XelisWalletMultisigSigningRequest?)
    record;
    try {
      if (amountAtomic == _selectedAssetBalance) {
        record = await commands.burnAll(asset: asset, feePolicy: feePolicy);
      } else {
        record = await commands.burn(
          amountAtomic: amountAtomic,
          asset: asset,
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

    if (!identical(ref.read(activeWalletRepositoryProvider), sessionIdentity)) {
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
    } else if (record.$1 != null) {
      ref
          .read(transactionReviewProvider.notifier)
          .setPreparedBurnTransaction(
            record.$1!,
            sessionIdentity: sessionIdentity,
          );
    } else {
      return;
    }

    if (mounted) {
      await context.push(AuthAppScreen.transactionReview.toPath);
    }
  }
}
