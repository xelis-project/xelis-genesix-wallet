import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/open_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/banner_widget.dart';

class OpenWalletWidget extends ConsumerStatefulWidget {
  const OpenWalletWidget({super.key});

  @override
  ConsumerState<OpenWalletWidget> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletWidget> {
  final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  bool _hidePassword = true;

  String? _selectedWallet;

  Future<void>? _pendingLogIn;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final userThemeMode = ref.watch(userThemeModeProvider);
    final ScalableImageWidget banner =
        getBanner(context, userThemeMode.themeMode);
    final openWalletState = ref.watch(openWalletProvider);

    _selectedWallet = openWalletState.walletCurrentlyUsed;

    return FutureBuilder(
        future: _pendingLogIn,
        builder: (context, snapshot) {
          // final isErrored = snapshot.hasError &&
          //     snapshot.connectionState != ConnectionState.waiting;

          final isWaiting = snapshot.connectionState == ConnectionState.waiting;

          return FormBuilder(
            key: _openFormKey,
            onChanged: () => _openFormKey.currentState!.save(),
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
                            loc.sign_in,
                            style: context.headlineLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                loc.no_wallet,
                                style: context.bodyLarge,
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go(
                                    AppScreen.auth.toPath,
                                    extra: LoginAction.create,
                                  );
                                },
                                child: Text(loc.create_wallet_button),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownMenu<String>(
                            expandedInsets: EdgeInsets.zero,
                            label: Text(
                              loc.wallet,
                              style: context.bodyLarge,
                            ),
                            requestFocusOnTap: true,
                            initialSelection:
                                openWalletState.walletCurrentlyUsed,
                            dropdownMenuEntries: openWalletState.wallets.entries
                                .map((entry) => DropdownMenuEntry<String>(
                                    value: entry.key, label: entry.key))
                                .toList(),
                            onSelected: (v) {
                              setState(() {
                                _selectedWallet = v;
                              });
                            },
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
                            validator: FormBuilderValidators.required(),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 200,
                              child: FilledButton(
                                onPressed: isWaiting
                                    ? null
                                    : () async {
                                        if (_openFormKey.currentState
                                                ?.saveAndValidate() ??
                                            false) {
                                          final password = _openFormKey
                                              .currentState
                                              ?.value['password'] as String?;

                                          if (_selectedWallet != null &&
                                              password != null) {
                                            final future = ref
                                                .read(authenticationProvider
                                                    .notifier)
                                                .openWallet(
                                                    _selectedWallet!, password);

                                            setState(() {
                                              _pendingLogIn = future;
                                            });
                                          }
                                        }
                                      },
                                child: Text(
                                  loc.open_wallet_button,
                                  style: context.titleMedium!.copyWith(
                                      color: context.colors.onPrimary),
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
