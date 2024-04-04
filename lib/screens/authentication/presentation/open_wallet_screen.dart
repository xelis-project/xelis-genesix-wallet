import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/network_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/router/route_utils.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/banner_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_textfield_widget.dart';

class OpenWalletScreen extends ConsumerStatefulWidget {
  const OpenWalletScreen({super.key});

  @override
  ConsumerState<OpenWalletScreen> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletScreen> {
  final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  String? _selectedWallet;

  //late Widget _widgetOpening;

/*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_initOpenButton();
  }


  void _initOpenButton() {
    final loc = ref.read(appLocalizationsProvider);
    _widgetOpening = FilledButton(
      onPressed: _openWallet,
      child: Text(loc.open_wallet_button),
    );
  }*/

  void _openWallet() async {
    if (_openFormKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final password = _openFormKey.currentState?.value['password'] as String?;

      if (_selectedWallet != null && password != null) {
        setState(() {
          //_widgetOpening = const CircularProgressIndicator();
        });

        try {
          context.loaderOverlay.show();
          await ref
              .read(authenticationProvider.notifier)
              .openWallet(_selectedWallet!, password);
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

        /*  //.then((value) {
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
        });*/
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final settings = ref.watch(settingsProvider);
    //final ScalableImageWidget banner = getBanner(context, settings.theme);
    final networkWallet = ref.watch(networkWalletProvider);
    var openWallet = networkWallet.getOpenWallet(settings.network);
    var wallets = networkWallet.getWallets(settings.network);

    _selectedWallet ??= openWallet;

    return Scaffold(
      body: Background(
        child: FormBuilder(
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
                        /*Row(
                          children: [
                            const Spacer(),
                            Hero(
                              tag: 'banner',
                              child: banner,
                            ),
                            const Spacer(),
                          ],
                        ),*/
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
                                  AppScreen.createWallet.toPath,
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
                          initialSelection: openWallet,
                          dropdownMenuEntries: wallets.entries
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
                        PasswordTextField(
                          textField: FormBuilderTextField(
                            name: 'password',
                            style: context.bodyLarge,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: loc.password,
                            ),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        const SizedBox(height: Spaces.medium),
                        FilledButton(
                          onPressed: _openWallet,
                          child: Text(loc.open_wallet_button),
                        ),
                        const Spacer(
                          flex: 3,
                        ),
                        OutlinedButton.icon(
                          label: const Text('Settings'),
                          icon: const Icon(
                            Icons.settings,
                            size: Spaces.medium,
                          ),
                          onPressed: () =>
                              {context.push(AppScreen.settings.toPath)},
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
