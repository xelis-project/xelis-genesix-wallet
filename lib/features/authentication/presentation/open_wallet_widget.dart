import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/isar/isar_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class OpenWalletWidget extends ConsumerStatefulWidget {
  const OpenWalletWidget({
    super.key,
  });

  @override
  ConsumerState createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletWidget> {
  final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final wallets = ref.watch(existingWalletsProvider);
    return wallets.when(
      data: (data) => Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 4,
            child: FormBuilder(
              key: _openFormKey,
              onChanged: () => _openFormKey.currentState!.save(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: FormBuilderDropdown(
                      name: 'wallet_name',
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      enabled: data.isNotEmpty,
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
                      initialValue: data.isNotEmpty ? data.first : '',
                      items: data.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(
                            value ?? '',
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
                      validator: FormBuilderValidators.required(),
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
                          onPressed: data.isEmpty
                              ? null
                              : () {
                                  if (_openFormKey.currentState
                                          ?.saveAndValidate() ??
                                      false) {
                                    logger.info(
                                      _openFormKey.currentState?.value
                                          .toString(),
                                    );
                                    final walletName = _openFormKey.currentState
                                        ?.value['wallet_name'] as String?;
                                    final password = _openFormKey.currentState
                                        ?.value['password'] as String?;
                                    if (walletName != null &&
                                        password != null) {
                                      ref
                                          .read(authenticationProvider.notifier)
                                          .openWallet(walletName, password);
                                    }
                                  }
                                },
                          child: Text(loc.open_wallet_button),
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
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
