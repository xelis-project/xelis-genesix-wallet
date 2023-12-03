import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class CreateWalletWidget extends ConsumerStatefulWidget {
  const CreateWalletWidget({
    super.key,
  });

  @override
  ConsumerState createState() => _CreateWalletWidgetState();
}

class _CreateWalletWidgetState extends ConsumerState<CreateWalletWidget> {
  final _createFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_createFormKey');
  bool _seedRequired = false;
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Row(
      children: [
        const Spacer(),
        Expanded(
          flex: 4,
          child: FormBuilder(
            key: _createFormKey,
            onChanged: () => _createFormKey.currentState!.save(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: FormBuilderSwitch(
                    name: 'seed_switch',
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    initialValue: _seedRequired,
                    title: Text(
                      loc.seed_option,
                      style: context.bodyLarge,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _seedRequired = value!;
                      });
                    },
                  ),
                ),
                Visibility(
                  visible: _seedRequired,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: FormBuilderTextField(
                      name: 'seed',
                      style: context.bodyLarge,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: loc.seed,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: FormBuilderValidators.compose([
                        // TODO better add seed validator
                        FormBuilderValidators.match(
                          '(?:[a-zA-Z]+ ){24}[a-zA-Z]+',
                          errorText: 'Invalid seed',
                        ),
                        // FormBuilderValidators.minWordsCount(25),
                        // FormBuilderValidators.maxWordsCount(25),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FormBuilderTextField(
                    name: 'wallet_name',
                    style: context.bodyLarge,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: loc.wallet_name,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: FormBuilderValidators.compose([
                      // TODO check if wallet name already exists
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minLength(1),
                      FormBuilderValidators.maxLength(64),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FormBuilderTextField(
                    name: 'password',
                    style: context.bodyLarge,
                    autocorrect: false,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: loc.password,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: _hidePassword
                            ? Icon(
                                Icons.visibility_off_outlined,
                                color: context.colors.secondary,
                              )
                            : Icon(
                                Icons.visibility_outlined,
                                color: context.colors.primary,
                              ),
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                      ),
                    ),
                    onSaved: (value) {},
                    onEditingComplete: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Consumer(
                    builder: (
                      context,
                      ref,
                      child,
                    ) {
                      return OutlinedButton(
                        onPressed: () {
                          if (_createFormKey.currentState?.saveAndValidate() ??
                              false) {
                            logger.info(
                              _createFormKey.currentState?.value.toString(),
                            );
                            final walletName = _createFormKey
                                .currentState?.value['wallet_name'] as String?;
                            final password = _createFormKey
                                .currentState?.value['password'] as String?;
                            final seed = _createFormKey
                                .currentState?.value['seed'] as String?;
                            if (walletName != null && password != null) {
                              ref
                                  .read(authenticationProvider.notifier)
                                  .createWallet(walletName, password, seed);
                            }
                          }
                        },
                        child: Text(loc.create_wallet_button),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
