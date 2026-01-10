import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transaction_review_dialog_new.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
// import 'package:genesix/features/wallet/domain/transaction_review_state.dart';

class BurnScreenNew extends ConsumerStatefulWidget {
  const BurnScreenNew({super.key});

  @override
  ConsumerState<BurnScreenNew> createState() => _BurnScreenNewState();
}

class _BurnScreenNewState extends ConsumerState<BurnScreenNew>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late final FSelectController<MapEntry<String, AssetData>> _assetController =
      FSelectController<MapEntry<String, AssetData>>(vsync: this);

  String? _selectedAsset;
  String _selectedAssetBalance = AppResources.zeroBalance;

  @override
  void initState() {
    super.initState();

    final Map<String, String> balances = ref.read(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.read(
      walletStateProvider.select((value) => value.knownAssets),
    );

    final firstValidBalance = balances.entries
        .where((entry) => assets.containsKey(entry.key))
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

    final Map<String, String> balances = ref.watch(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    final Map<String, AssetData> assets = ref.watch(
      walletStateProvider.select((value) => value.knownAssets),
    );

    final validAssets = balances.entries
        .where((balance) => assets.containsKey(balance.key))
        .toList();

    const inputHeight = 40.0;

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
                    style: context.theme.typography.sm.copyWith(
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
                              controller: _amountController,
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
                                final parsed = double.tryParse(value.trim());
                                if (parsed == null) {
                                  return loc.must_be_numeric_error;
                                }
                                if (parsed <= 0) {
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
                                style: FButtonStyle.outline(),
                                onPress: () {
                                  final selected = _assetController.value;
                                  if (selected != null) {
                                    _selectedAsset = selected.key;
                                    _selectedAssetBalance =
                                        balances[_selectedAsset] ??
                                        AppResources.zeroBalance;
                                  }
                                  _amountController.text =
                                      _selectedAssetBalance;
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
                        style: context.theme.typography.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),

                      // Asset select
                      FSelect<MapEntry<String, AssetData>>.rich(
                        controller: _assetController,
                        enabled: validAssets.isNotEmpty,
                        hint: validAssets.isEmpty
                            ? loc.no_balance_to_burn
                            : loc.select_asset,
                        format: (entry) => entry.value.name,
                        children: validAssets.map((entry) {
                          final assetData = assets[entry.key]!;
                          final balance =
                              balances[entry.key] ?? AppResources.zeroBalance;
                          return FSelectItem<MapEntry<String, AssetData>>(
                            value: MapEntry(entry.key, assetData),
                            title: Text(assetData.name),
                            subtitle: Text('$balance ${assetData.ticker}'),
                          );
                        }).toList(),
                        onChange: (entry) {
                          if (entry != null) {
                            setState(() {
                              _selectedAsset = entry.key;
                              _selectedAssetBalance =
                                  balances[_selectedAsset] ??
                                  AppResources.zeroBalance;
                            });
                          }
                        },
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
                    if (context.isWideScreen) const Spacer(),
                    Expanded(
                      child: FButton(
                        style: FButtonStyle.primary(),
                        onPress: validAssets.isEmpty ? null : _reviewBurn,
                        child: Text(loc.review_burn),
                      ),
                    ),
                    if (context.isWideScreen) const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reviewBurn() async {
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

    if (_selectedAssetBalance == AppResources.zeroBalance) {
      ref
          .read(toastProvider.notifier)
          .showWarning(title: loc.no_balance_to_burn);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amountText = _amountController.text.trim();
    final asset = _selectedAsset!;

    context.loaderOverlay.show();

    (TransactionSummary?, String?) record;
    if (amountText == _selectedAssetBalance) {
      record = await ref
          .read(walletStateProvider.notifier)
          .burnAll(asset: asset);
    } else {
      record = await ref
          .read(walletStateProvider.notifier)
          .burn(amount: double.parse(amountText), asset: asset);
    }

    if (mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }

    // MULTISIG: hash to sign
    if (record.$2 != null) {
      ref.read(transactionReviewProvider.notifier).signaturePending(record.$2!);
    }
    // SIMPLE BURN: summary
    else if (record.$1 != null) {
      ref
          .read(transactionReviewProvider.notifier)
          .setBurnTransaction(record.$1!);
    } else {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      return;
    }

    if (mounted) {
      await showFDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext, style, animation) {
          return TransactionReviewDialogNew(style, animation);
        },
      );
    }
  }
}
