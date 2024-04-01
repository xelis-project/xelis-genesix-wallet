import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/open_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/router/route_utils.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
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

  late Widget _widgetOpening;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initOpenButton();
  }

  void _initOpenButton() {
    final loc = ref.read(appLocalizationsProvider);
    _widgetOpening = SizedBox(
      width: 200,
      child: FilledButton(
        onPressed: _createWallet,
        child: Text(
          loc.open_wallet_button,
          style: context.titleMedium!.copyWith(color: context.colors.onPrimary),
        ),
      ),
    );
  }

  void _createWallet() {
    if (_openFormKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final password = _openFormKey.currentState?.value['password'] as String?;

      if (_selectedWallet != null && password != null) {
        setState(() {
          _widgetOpening = const CircularProgressIndicator();
        });

        ref
            .read(authenticationProvider.notifier)
            .openWallet(_selectedWallet!, password)
            .then((value) {
          setState(() {
            _widgetOpening = Column(
              children: [
                Icon(
                  Icons.check_rounded,
                  color: context.colors.primary,
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  loc.open_wallet_message,
                  style: context.bodyMedium
                      ?.copyWith(color: context.colors.primary),
                ),
              ],
            );
          });
        }, onError: (_) {
          setState(() {
            _initOpenButton();
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final settings = ref.watch(settingsProvider);
    final ScalableImageWidget banner =
        getBanner(context, settings.theme);
    final openWalletState = ref.watch(openWalletProvider);

    _selectedWallet ??= openWalletState.walletCurrentlyUsed;

    return FormBuilder(
      key: _openFormKey,
      onChanged: () => _openFormKey.currentState!.save(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spaces.large),
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
                        Hero(
                          tag: 'banner',
                          child: banner,
                        ),
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
                    const SizedBox(height: Spaces.small),
                    DropdownMenu<String>(
                      expandedInsets: EdgeInsets.zero,
                      label: Text(
                        loc.wallet,
                        style: context.bodyLarge,
                      ),
                      requestFocusOnTap: true,
                      initialSelection: openWalletState.walletCurrentlyUsed,
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
                    const SizedBox(height: Spaces.medium),
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
                                  Icons.visibility_off_rounded,
                                  color: context.colors.secondary,
                                )
                              : Icon(
                                  Icons.visibility_rounded,
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
                    const SizedBox(height: Spaces.medium),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Spaces.small),
                        child: AnimatedSwitcher(
                          duration: const Duration(
                              milliseconds: AppDurations.animNormal),
                          child: _widgetOpening,
                        ),
                      ),
                    ),
                    const Spacer(
                      flex: 3,
                    ),
                    TextButton(
                      onPressed: () => {
                        context.push(AppScreen.settings.toPath)
                      },
                      child: const Text('Settings'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
