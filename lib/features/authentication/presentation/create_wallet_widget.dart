import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/open_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/banner_widget.dart';
import 'package:xelis_mobile_wallet/features/router/login_action_codec.dart';

class CreateWalletWidget extends ConsumerStatefulWidget {
  const CreateWalletWidget({super.key});

  @override
  ConsumerState createState() => _CreateWalletWidgetState();
}

class _CreateWalletWidgetState extends ConsumerState<CreateWalletWidget> {
  final _createFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_createFormKey');
  bool _seedRequired = false;
  bool _hidePassword = true;

  Future<void>? _pendingLogIn;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final userThemeMode = ref.watch(userThemeModeProvider);
    final ScalableImageWidget banner =
        getBanner(context, userThemeMode.themeMode);

    final openWalletState = ref.watch(openWalletProvider);

    return FutureBuilder(
        future: _pendingLogIn,
        builder: (context, snapshot) {
          // final isErrored = snapshot.hasError &&
          //     snapshot.connectionState != ConnectionState.waiting;

          final isWaiting = snapshot.connectionState == ConnectionState.waiting;

          return FormBuilder(
            key: _createFormKey,
            onChanged: () => _createFormKey.currentState!.save(),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Row(
                            children: [
                              const Spacer(),
                              banner,
                              const Spacer(),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            loc.create,
                            style: context.headlineLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                loc.already_wallet,
                                style: context.bodyLarge,
                              ),
                              TextButton(
                                onPressed: openWalletState.wallets.isNotEmpty
                                    ? () {
                                        context.go(
                                          AppScreen.auth.toPath,
                                          extra: LoginAction.open,
                                        );
                                      }
                                    : null,
                                child: Text(loc.open_wallet_button),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FormBuilderSwitch(
                            name: 'seed_switch',
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
                          Visibility(
                            visible: _seedRequired,
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                FormBuilderTextField(
                                  name: 'seed',
                                  style: context.bodyLarge,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: loc.seed,
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'wallet_name',
                            style: context.bodyLarge,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: loc.wallet_name,
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(1),
                              FormBuilderValidators.maxLength(64),
                              // check if this wallet name already exists.
                              (val) {
                                if (openWalletState.wallets.containsKey(val)) {
                                  return loc.wallet_name_already_exists;
                                }
                                return null;
                              },
                            ]),
                          ),
                          const SizedBox(height: 16),
                          FormBuilderTextField(
                            name: 'password',
                            style: context.bodyLarge,
                            autocorrect: false,
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              labelText: loc.password,
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
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 200,
                              child: FilledButton(
                                onPressed: isWaiting
                                    ? null
                                    : () async {
                                        if (_createFormKey.currentState
                                                ?.saveAndValidate() ??
                                            false) {
                                          final walletName = _createFormKey
                                              .currentState
                                              ?.value['wallet_name'] as String?;
                                          final password = _createFormKey
                                              .currentState
                                              ?.value['password'] as String?;
                                          final seed = _createFormKey
                                              .currentState
                                              ?.value['seed'] as String?;

                                          if (walletName != null &&
                                              password != null) {
                                            final future = ref
                                                .read(authenticationProvider
                                                    .notifier)
                                                .createWallet(
                                                    walletName, password, seed);

                                            setState(() {
                                              _pendingLogIn = future;
                                            });
                                          }
                                        }
                                      },
                                child: Text(
                                  loc.create_wallet_button,
                                  style: context.titleMedium!.copyWith(
                                      color: context.colors.onSecondary),
                                ),
                              ),
                            ),
                          ),
                          if (isWaiting) ...[
                            const SizedBox(height: 16),
                            const Center(child: CircularProgressIndicator()),
                          ],
                          const Spacer(
                            flex: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
