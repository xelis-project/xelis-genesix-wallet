import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/shared/widgets/components/password_textfield_widget.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _changePasswordKey =
      GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  void _changePassword() async {
    if (_changePasswordKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final oldPassword =
          _changePasswordKey.currentState?.value['old_password'] as String;
      final newPassword =
          _changePasswordKey.currentState?.value['new_password'] as String;
      final confirmNewPassword = _changePasswordKey
          .currentState?.value['confirm_new_password'] as String;

      if (oldPassword == newPassword) {
        _changePasswordKey.currentState?.fields['new_password']
            ?.invalidate(loc.same_old_new_password_error);
      } else if (newPassword != confirmNewPassword) {
        _changePasswordKey.currentState?.fields['confirm_new_password']
            ?.invalidate(loc.not_match_new_password_error);
      } else {
        try {
          context.loaderOverlay.show();

          await ref
              .read(walletStateProvider)
              .nativeWalletRepository!
              .changePassword(
                  oldPassword: oldPassword, newPassword: newPassword);

          ref
              .read(snackBarMessengerProvider.notifier)
              .showInfo(loc.password_changed);
        } catch (e) {
          ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
        }

        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return CustomScaffold(
      backgroundColor: Colors.transparent,
      appBar: GenericAppBar(title: loc.change_password),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spaces.large, Spaces.none, Spaces.large, Spaces.large),
        child: FormBuilder(
          key: _changePasswordKey,
          onChanged: () => _changePasswordKey.currentState!.save(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: Spaces.large),
              // Text(loc.old_password, style: context.bodyLarge),
              // const SizedBox(height: Spaces.small),
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'old_password',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: loc.old_password,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              // Text(loc.new_password, style: context.bodyLarge),
              // const SizedBox(height: Spaces.small),
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'new_password',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: loc.new_password,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              // Text(loc.confirm_password, style: context.bodyLarge),
              // const SizedBox(height: Spaces.small),
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'confirm_new_password',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: loc.confirm_password,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(height: Spaces.large),
              TextButton.icon(
                onPressed: () {
                  _changePassword();
                },
                icon: const Icon(Icons.edit),
                label: Text(
                  loc.confirm_button,
                  style: context.titleMedium!
                      .copyWith(color: context.colors.onPrimary),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
