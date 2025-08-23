import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/input_decoration_old.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog_old.dart';
import 'package:go_router/go_router.dart';

class SignTransactionDialog extends ConsumerStatefulWidget {
  const SignTransactionDialog({super.key});

  @override
  ConsumerState createState() => _SignTransactionDialogState();
}

class _SignTransactionDialogState extends ConsumerState<SignTransactionDialog> {
  final _signTransactionFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_signFormKey',
  );

  Future<String>? transactionSignature;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return GenericDialog(
      scrollable: false,
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  loc.sign_transaction,
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        constraints: BoxConstraints(maxWidth: 600),
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.sign_transaction_dialog_message,
              style: context.bodyMedium!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.large),
            FormBuilder(
              key: _signTransactionFormKey,
              child: FormBuilderTextField(
                name: 'transactionHash',
                style: context.bodyMedium,
                autocorrect: false,
                keyboardType: TextInputType.text,
                decoration: context.textInputDecoration.copyWith(
                  labelText: loc.transaction_hash,
                  suffixIcon: IconButton(
                    hoverColor: Colors.transparent,
                    onPressed: () {
                      _signTransactionFormKey
                          .currentState
                          ?.fields['transactionHash']
                          ?.reset();
                      setState(() {
                        transactionSignature = null;
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: context.moreColors.mutedColor,
                    ),
                  ),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: loc.field_required_error,
                  ),
                  FormBuilderValidators.equalLength(
                    64,
                    errorText: loc.sign_transaction_formfield_error,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: Spaces.large),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: FutureBuilder(
                future: transactionSignature,
                builder: (context, snapshot) {
                  if (snapshot.hasError &&
                      snapshot.connectionState != ConnectionState.none) {
                    return Column(
                      children: [
                        Text(
                          loc.error,
                          style: context.bodyMedium?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                        Text(
                          (snapshot.error as AnyhowException).message,
                          style: context.bodyMedium?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      ],
                    );
                  } else if (snapshot.hasData &&
                      snapshot.connectionState != ConnectionState.none) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              loc.signature,
                              style: context.bodyMedium!.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () => copyToClipboard(
                                snapshot.requireData,
                                ref,
                                loc.copied,
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              tooltip: loc.copy_signature,
                            ),
                          ],
                        ),
                        const SizedBox(height: Spaces.small),
                        SelectableText(snapshot.data as String),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: _signTransaction, child: Text(loc.sign))],
    );
  }

  Future<void> _signTransaction() async {
    if (_signTransactionFormKey.currentState?.saveAndValidate() ?? false) {
      final transactionHash =
          _signTransactionFormKey.currentState?.value['transactionHash']
              as String?;
      if (transactionHash != null) {
        try {
          final future = ref
              .read(walletStateProvider.notifier)
              .signTransactionHash(transactionHash.trim());
          setState(() {
            transactionSignature = future;
          });
        } finally {}
      }
    }
  }
}
