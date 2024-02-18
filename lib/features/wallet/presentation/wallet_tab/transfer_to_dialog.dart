import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class TransferToDialog extends ConsumerStatefulWidget {
  const TransferToDialog({super.key});

  @override
  ConsumerState createState() => _TransferToDialogState();
}

class _TransferToDialogState extends ConsumerState<TransferToDialog> {
  final _transferFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_transferFormKey');

  late double _remainingBalance;
  double _amountToTransfer = 0.0;

  Future<String?>? _pendingTransfer;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletSnapshot = ref.watch(walletStateProvider);
    _remainingBalance =
        double.parse(walletSnapshot.xelisBalance) - _amountToTransfer;

    return FutureBuilder(
      future: _pendingTransfer,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        // final isErrored = snapshot.hasError &&
        //     snapshot.connectionState != ConnectionState.waiting;
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final isDone = snapshot.connectionState == ConnectionState.done;

        return AlertDialog(
          // insetPadding: EdgeInsets.zero,
          scrollable: true,
          title: Padding(
            padding: const EdgeInsets.all(8),
            child: isDone
                ? Center(
                    child: Icon(
                      Icons.done_rounded,
                      size: 50.0,
                      color: context.colors.primary,
                    ),
                  )
                : Text(
                    loc.transfer_to,
                    style: context.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
          ),
          content: Builder(builder: (context) {
            // var height = context.mediaSize.height;
            var width = context.mediaSize.width;

            return SizedBox(
              // height: height,
              width: width,
              child: isDone
                  ? Column(
                      children: [
                        Text(
                          loc.tx_hash,
                          style: context.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          snapshot.data ?? loc.oups,
                          style: context.bodySmall,
                        ),
                      ],
                    )
                  : FormBuilder(
                      key: _transferFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${loc.remaining_balance}: ',
                                style: context.bodySmall,
                              ),
                              Text(
                                _remainingBalance.toString(),
                                style: context.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'amount',
                            style: context.bodyMedium,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: loc.amount,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                final amount = double.tryParse(val);
                                setState(() {
                                  _amountToTransfer = amount ?? 0.0;
                                });
                              }
                            },
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: loc.field_required_error),
                              FormBuilderValidators.numeric(
                                  errorText: loc.must_be_numeric_error),
                              (val) {
                                if (_remainingBalance < 0) {
                                  return loc.insufficient_funds_error;
                                }
                                if (val != null) {
                                  final amount = double.tryParse(val);
                                  if (amount == 0) {
                                    return loc.invalid_amount_error;
                                  }
                                }
                                return null;
                              }
                            ]),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'address',
                            style: context.bodyMedium,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: loc.receiver_address,
                              border: const OutlineInputBorder(),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                  errorText: loc.field_required_error),
                              FormBuilderValidators.minLength(65,
                                  errorText: loc.invalid_address_format_error),
                              FormBuilderValidators.maxLength(65,
                                  errorText: loc.invalid_address_format_error),
                            ]),
                          ),
                          if (isWaiting) ...[
                            const SizedBox(height: 16),
                            const Center(child: CircularProgressIndicator()),
                          ]
                        ],
                      ),
                    ),
            );
          }),
          actions: <Widget>[
            if (isDone) ...[
              TextButton(
                onPressed: () => context.pop(),
                child: Text(loc.ok_button),
              ),
            ],
            if (!isWaiting && !isDone) ...[
              TextButton(
                onPressed: () => context.pop(),
                child: Text(loc.cancel_button),
              ),
              TextButton(
                onPressed: () async {
                  if (_transferFormKey.currentState?.saveAndValidate() ??
                      false) {
                    final amount = _transferFormKey
                        .currentState?.fields['amount']?.value as String;
                    final address = _transferFormKey
                        .currentState?.fields['address']?.value as String;

                    final future = ref
                        .read(walletStateProvider.notifier)
                        .send(amount: double.parse(amount), address: address);

                    setState(() {
                      _pendingTransfer = future;
                    });
                  }
                },
                child: Text(loc.confirm_button),
              ),
            ]
          ],
        );
      },
    );
  }
}
