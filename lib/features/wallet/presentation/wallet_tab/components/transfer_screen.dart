import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/transfer_review_dialog.dart';
import 'package:genesix/rust_bridge/api/utils.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _transferFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_transferFormKey');

  void _reviewTransfer() async {
    if (_transferFormKey.currentState?.saveAndValidate() ?? false) {
      final amount =
          _transferFormKey.currentState?.fields['amount']?.value as String;
      final address =
          _transferFormKey.currentState?.fields['address']?.value as String;

      try {
        context.loaderOverlay.show();

        final xelisBalance =
            ref.read(walletStateProvider.select((value) => value.xelisBalance));

        TransactionSummary? tx;
        if (amount.trim() == xelisBalance) {
          tx = await ref
              .read(walletStateProvider.notifier)
              .createAllXelisTransaction(destination: address.trim());
        } else {
          tx = await ref
              .read(walletStateProvider.notifier)
              .createXelisTransaction(
                  amount: double.parse(amount), destination: address.trim());
        }

        if (mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TransferReviewDialog(tx!);
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
    final xelisBalance =
        ref.watch(walletStateProvider.select((value) => value.xelisBalance));

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.transfer),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Spaces.large, Spaces.none, Spaces.large, Spaces.large),
        children: [
          FormBuilder(
            key: _transferFormKey,
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
                  decoration: context.textInputDecoration.copyWith(
                    labelText: '0.00000000',
                    labelStyle: context.headlineLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(Spaces.small),
                      child: TextButton(
                        onPressed: () => _transferFormKey
                            .currentState?.fields['amount']
                            ?.didChange(xelisBalance),
                        child: Text(loc.max),
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
                  loc.recipient,
                  style: context.headlineSmall,
                ),
                const SizedBox(height: Spaces.small),
                FormBuilderTextField(
                  name: 'address',
                  style: context.bodyMedium,
                  autocorrect: false,
                  decoration: context.textInputDecoration.copyWith(
                    labelText: loc.receiver_address,
                  ),
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
              ],
            ),
          ),
          const SizedBox(height: Spaces.large),
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
}
