import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/network_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/layout_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/components/seed_on_creation_widget.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_textfield_widget.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  ConsumerState createState() => _CreateWalletWidgetState();
}

class _CreateWalletWidgetState extends ConsumerState<CreateWalletScreen> {
  final _createFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_createFormKey');

  bool _seedRequired = false;

  void _createWallet() async {
    if (_createFormKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final walletName =
          _createFormKey.currentState?.value['wallet_name'] as String?;
      final password =
          _createFormKey.currentState?.value['password'] as String?;
      final confirmPassword =
          _createFormKey.currentState?.value['confirm_password'] as String?;
      final seed = _createFormKey.currentState?.value['seed'] as String?;

      if (walletName != null &&
          password != null &&
          password == confirmPassword) {
        /* setState(() {
          _widgetCreation = const CircularProgressIndicator();
        });*/

        try {
          context.loaderOverlay.show();
          await ref
              .read(authenticationProvider.notifier)
              .createWallet(walletName, password, seed);
        } catch (e) {
          ref
              .read(snackbarContentProvider.notifier)
              .setContent(SnackbarEvent.error(
                message: e.toString(),
              ));
        }

        if (mounted) {
          context.loaderOverlay.hide();
        }

        /*      .then((value) {
          setState(() {
            _widgetCreation = Column(
              children: [
                Icon(
                  Icons.check_rounded,
                  color: context.colors.primary,
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  loc.create_wallet_message,
                  style: context.bodyMedium
                      ?.copyWith(color: context.colors.primary),
                ),
              ],
            );
          });
          if (seed == null) {
            _showSeed(password);
          }
        }, onError: (_) {
          setState(() {
            _initCreateButton();
          });
        });*/
      }
    }
  }

  void _showSeed(String password) {
    Timer.run(() => showDialog<void>(
        context: context,
        builder: (BuildContext context) => SeedOnCreationWidget(password)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final settings = ref.watch(settingsProvider);

    final networkWallet = ref.watch(networkWalletProvider);
    var wallets = networkWallet.getWallets(settings.network);

    return Background(
      child: FormBuilder(
        key: _createFormKey,
        onChanged: () => _createFormKey.currentState!.save(),
        child: ListView(
          padding: const EdgeInsets.all(Spaces.large),
          children: [
            const BackHeader(title: 'Create new wallet'),
            const SizedBox(height: Spaces.medium),
            FormBuilderSwitch(
              name: 'seed_switch',
              initialValue: _seedRequired,
              title: Text(
                'Create from seed',
                style: context.bodyLarge,
              ),
              onChanged: (value) {
                setState(() {
                  _seedRequired = value!;
                });
              },
            ),
            const SizedBox(height: Spaces.small),
            const Divider(),
            Visibility(
              visible: _seedRequired,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormBuilderTextField(
                    name: 'seed',
                    style: context.bodyLarge,
                    maxLines: null,
                    minLines: 5,
                    autocorrect: false,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: loc.seed,
                      alignLabelWithHint: true,
                    ),
                    validator: FormBuilderValidators.compose([
                      // TODO: add better seed validator
                      FormBuilderValidators.match(
                        '(?:[a-zA-Z]+ ){24}[a-zA-Z]+',
                        errorText: loc.invalid_seed,
                      ),
                      // FormBuilderValidators.minWordsCount(25),
                      // FormBuilderValidators.maxWordsCount(25),
                    ]),
                  ),
                  const SizedBox(height: Spaces.small),
                  TextButton.icon(
                    onPressed: () {
                      context.pop();
                    },
                    icon: const Icon(Icons.file_open_outlined, size: 18,),
                    label: Text(
                      'Load from file',
                      style: context.titleMedium!
                          .copyWith(color: context.colors.onPrimary, fontSize: 14),
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
            const SizedBox(height: Spaces.small),
            FormBuilderTextField(
              name: 'wallet_name',
              style: context.bodyLarge, //!.copyWith(color: Colors.white),
              autocorrect: false,
              decoration: InputDecoration(
                labelText: loc.wallet_name,
                //labelStyle: asd,.
                //labelStyle: context.bodyLarge
                /*labelStyle: context.bodyLarge!.copyWith(color: Colors.white),
                            filled: true,
                            fillColor: Colors.black.withOpacity(.2),
                            hoverColor: Colors.black.withOpacity(0),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 1),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.transparent, width: 0),
                            ),*/
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(1),
                FormBuilderValidators.maxLength(64),
                (val) {
                  // check if this wallet name already exists.
                  if (wallets.containsKey(val)) {
                    return loc.wallet_name_already_exists;
                  }
                  return null;
                },
              ]),
            ),
            const SizedBox(height: Spaces.medium),
            PasswordTextField(
              textField: FormBuilderTextField(
                name: 'password',
                style: context.bodyLarge,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: loc.password,
                ),
              ),
            ),
            const SizedBox(height: Spaces.medium),
            PasswordTextField(
              textField: FormBuilderTextField(
                name: 'confirm_password',
                style: context.bodyLarge,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Retype password',
                ),
              ),
            ),
            const SizedBox(height: Spaces.medium),
            TextButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.wallet),
              label: Text(
                'Create',
                style: context.titleMedium!
                    .copyWith(color: context.colors.onPrimary),
              ),
            )
          ],
        ),
      ),
    );
  }
}
