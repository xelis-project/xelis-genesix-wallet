import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transaction_dialog_old.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BurnScreen extends ConsumerStatefulWidget {
  const BurnScreen({super.key});

  @override
  ConsumerState createState() => _BurnScreenState();
}

class _BurnScreenState extends ConsumerState<BurnScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  late final _assetController =
      FSelectController<MapEntry<String, AssetData>>();

  late String _selectedAssetBalance;
  String? _selectedAsset;
  late FocusNode _focusNodeAmount;

  @override
  void initState() {
    super.initState();
    _focusNodeAmount = FocusNode();
    final Map<String, String> balances = ref.read(
      walletStateProvider.select((value) => value.trackedBalances),
    );
    if (balances.isEmpty) {
      _selectedAssetBalance = AppResources.zeroBalance;
    } else {
      _selectedAssetBalance = balances.entries.first.value;
    }
  }

  @override
  dispose() {
    _focusNodeAmount.dispose();
    _scrollController.dispose();
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

    return FScaffold(
      header: Padding(
        padding: const EdgeInsets.only(top: Spaces.medium),
        child: FHeader.nested(
          prefixes: [
            Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: FHeaderAction.back(onPress: () => context.pop()),
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
                    FAlert(
                      title: Text(loc.warning),
                      subtitle: Text(loc.burn_screen_warning_message),
                    ),

                    const SizedBox(height: Spaces.large),

                    // Asset Selection
                    FSelect<MapEntry<String, AssetData>>.searchBuilder(
                      label: Text(loc.asset),
                      hint: validAssets.isEmpty
                          ? loc.no_balance_to_transfer
                          : loc.select_asset,
                      control: .managed(
                        controller: _assetController,
                        onChange: (assetEntry) {
                          if (assetEntry != null) {
                            setState(() {
                              _selectedAsset = assetEntry.key;
                              _selectedAssetBalance = balances[_selectedAsset]!;
                            });
                          }
                        },
                      ),
                      enabled: validAssets.isNotEmpty,
                      format: (assetEntry) {
                        final balance =
                            balances[assetEntry.key] ??
                            AppResources.zeroBalance;
                        return '${assetEntry.value.name} ($balance ${assetEntry.value.ticker})';
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
                            title: Text(
                              '${assetEntry.value.name} (${truncateText(assetEntry.key)})',
                            ),
                            subtitle: Text(
                              '$balance ${assetEntry.value.ticker}',
                            ),
                            value: assetEntry,
                          );
                        }).toList();
                      },
                      validator: (value) =>
                          value == null ? loc.field_required_error : null,
                    ),

                    const SizedBox(height: Spaces.large),

                    FTextFormField(
                      control: .managed(controller: _amountController),
                      label: Text(loc.amount),
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
                    const SizedBox(height: Spaces.large),
                    FButton(onPress: _reviewBurn, child: Text(loc.review_burn)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _reviewBurn() async {
    final selectedAsset = _assetController.value;
    if (selectedAsset != null) {
      _selectedAsset = selectedAsset.key;
      final Map<String, String> balances = ref.read(
        walletStateProvider.select((value) => value.trackedBalances),
      );
      _selectedAssetBalance =
          balances[_selectedAsset] ?? AppResources.zeroBalance;
    }

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
          .showWarning(title: loc.no_balance_to_burn);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final amount = _amountController.text.trim();

      _focusNodeAmount.unfocus();

      context.loaderOverlay.show();

      (TransactionSummary?, String?) record;
      if (amount.trim() == _selectedAssetBalance) {
        record = await ref
            .read(walletStateProvider.notifier)
            .burnAll(asset: _selectedAsset!);
      } else {
        record = await ref
            .read(walletStateProvider.notifier)
            .burn(amount: double.parse(amount), asset: _selectedAsset!);
      }

      if (record.$2 != null) {
        // multisig is enabled, hash to sign is returned
        ref
            .read(transactionReviewProvider.notifier)
            .signaturePending(record.$2!);
      } else if (record.$1 != null) {
        // no multisig, transaction summary is returned
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
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return TransactionDialog();
          },
        );
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
