import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
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
  final _openFormKey = GlobalKey<FormBuilderState>();
  bool _seedRequired = false;
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Expanded(
          flex: 4,
          child: FormBuilder(
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
                      ' Import your seed :',
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
                        labelText: 'Seed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSaved: (value) {},
                      onEditingComplete: () {},
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
                      labelText: 'Wallet Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSaved: (value) {},
                    onEditingComplete: () {},
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
                      labelText: 'Password',
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
                          logger.info('Create wallet');
                          ref
                              .read(
                                authenticationNotifierProvider.notifier,
                              )
                              .login();
                        },
                        child: const Text('Create wallet'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer()
      ],
    );
  }
}
