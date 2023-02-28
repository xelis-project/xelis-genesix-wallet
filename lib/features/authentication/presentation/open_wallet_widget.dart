import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

const walletNamesExample = <String>[
  'wallet_default',
  'wallet1',
  'wallet2',
  'wallet3',
  'wallet4',
];

class OpenWalletWidget extends ConsumerStatefulWidget {
  const OpenWalletWidget({
    super.key,
  });

  @override
  ConsumerState createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletWidget> {
  final _openFormKey = GlobalKey<FormBuilderState>();
  String selectedValue = walletNamesExample.first;
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Expanded(
          flex: 4,
          child: FormBuilder(
            key: _openFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FormBuilderDropdown(
                    name: 'wallet_name',
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    dropdownColor: context.colors.secondaryContainer,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_downward_outlined,
                      color: context.colors.secondary,
                    ),
                    style: context.bodyLarge,
                    initialValue: selectedValue,
                    items: walletNamesExample.map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: context.bodyLarge,
                        ),
                      );
                    }).toList(),
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
                    onEditingComplete: () {
                      _openFormKey.currentState?.save();
                    },
                    // validator: FormBuilderValidators.ip(),
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
                          logger.info('Open wallet');
                          ref
                              .read(
                                authenticationNotifierProvider.notifier,
                              )
                              .login();
                        },
                        child: const Text('Open wallet'),
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
