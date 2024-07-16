import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/burn_review_dialog.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BurnScreen extends ConsumerStatefulWidget {
  const BurnScreen({super.key});

  @override
  ConsumerState createState() => _BurnScreenState();
}

class _BurnScreenState extends ConsumerState<BurnScreen> {
  final _burnFormKey = GlobalKey<FormBuilderState>(debugLabel: '_burnFormKey');
  late String _selectedAssetBalance;

  @override
  void initState() {
    super.initState();
    final Map<String, String> assets =
        ref.read(walletStateProvider.select((value) => value.assets));
    _selectedAssetBalance = assets[assets.entries.first.key]!;
  }

  void _reviewBurn() async {
    if (_burnFormKey.currentState?.saveAndValidate() ?? false) {
      final amount =
          _burnFormKey.currentState?.fields['amount']?.value as String;
      final asset =
          _burnFormKey.currentState?.fields['assets']?.value as String;

      try {
        context.loaderOverlay.show();

        TransactionSummary? tx;
        if (double.parse(amount) == double.parse(_selectedAssetBalance)) {
          tx = await ref
              .read(walletStateProvider.notifier)
              .createBurnAllTransaction(asset: asset);
        } else {
          tx = await ref
              .read(walletStateProvider.notifier)
              .createBurnTransaction(
                  amount: double.parse(amount), asset: asset);
        }

        if (mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return BurnReviewDialog(tx!);
            },
          );
        }
      } catch (e) {
        ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final Map<String, String> assets =
        ref.watch(walletStateProvider.select((value) => value.assets));

    return Background(
      child: Scaffold(
        appBar: const GenericAppBar(title: 'Burn'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spaces.large, Spaces.none, Spaces.large, Spaces.large),
          children: [
            FormBuilder(
              key: _burnFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toBeginningOfSentenceCase(loc.amount) ?? loc.amount,
                    style: context.headlineSmall,
                  ),
                  const SizedBox(height: Spaces.small),
                  FormBuilderTextField(
                    name: 'amount',
                    style: context.headlineLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                    autocorrect: false,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '0.00000000',
                      labelStyle: context.headlineLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton(
                          onPressed: () => _burnFormKey
                              .currentState?.fields['amount']
                              ?.didChange(_selectedAssetBalance),
                          child: const Text('max'),
                        ),
                      ),
                    ),
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
                  const SizedBox(height: Spaces.medium),
                  Text(
                    loc.asset,
                    style: context.headlineSmall,
                  ),
                  const SizedBox(height: Spaces.small),
                  FormBuilderDropdown<String>(
                    name: 'assets',
                    initialValue: assets.entries.first.key,
                    items: assets.entries
                        .map((asset) => DropdownMenuItem(
                              value: asset.key,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(asset.key == xelisAsset
                                      ? 'XELIS'
                                      : truncateText(asset.key)),
                                  Text(asset.value),
                                ],
                              ),
                            ))
                        .toList(),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: loc.field_required_error),
                    ]),
                    onChanged: (val) {
                      logger.info(val);
                      if (val != null) {
                        setState(() {
                          _selectedAssetBalance = assets[val]!;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spaces.large),
            TextButton.icon(
              icon: const Icon(Icons.check_circle),
              onPressed: _reviewBurn,
              label: const Text('Review & Burn'),
            ),
          ],
        ),
      ),
    );
  }
}
