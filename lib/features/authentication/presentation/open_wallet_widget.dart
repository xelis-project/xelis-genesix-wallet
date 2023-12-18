import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/login_action_enum.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/banner_widget.dart';

class OpenWalletWidget extends ConsumerStatefulWidget {
  const OpenWalletWidget({super.key});

  @override
  ConsumerState<OpenWalletWidget> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletWidget> {
  final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  bool _hidePassword = true;

  String? selectedWallet;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final userThemeMode = ref.watch(userThemeModeProvider);
    final ScalableImageWidget banner =
        getBanner(context, userThemeMode.themeMode);

    final openWalletData = ref.watch(openWalletDataProvider);
    return openWalletData.when(
      data: (data) {
        selectedWallet ??= data['walletCurrentlyUsed'] as String;

        return FormBuilder(
          key: _openFormKey,
          onChanged: () => _openFormKey.currentState!.save(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 600),
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
                            // enabled: data.isNotEmpty,
                            label: Text(
                              loc.wallet,
                              style: context.bodyLarge,
                            ),
                            requestFocusOnTap: true,
                            initialSelection:
                                data['walletCurrentlyUsed'] as String,
                            dropdownMenuEntries: (data['walletSnapshots']
                                    as List<WalletSnapshot>)
                                .map<DropdownMenuEntry<String>>((entry) {
                              return DropdownMenuEntry<String>(
                                  value: entry.name!, label: entry.name!);
                            }).toList(),
                            onSelected: (v) {
                              setState(() {
                                selectedWallet = v;
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
                                onPressed: () {
                                  if (_openFormKey.currentState
                                          ?.saveAndValidate() ??
                                      false) {
                                    final password = _openFormKey.currentState
                                        ?.value['password'] as String?;

                                    if (selectedWallet != null &&
                                        password != null) {
                                      // logger
                                      //     .info('$selectedWallet : $password');
                                      ref
                                          .read(authenticationProvider.notifier)
                                          .openWallet(
                                              selectedWallet!, password);
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
          ),
        );
      },
      // TODO: temp
      error: (err, stack) => Center(child: Text('Error: $err')),
      // TODO: temp
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
