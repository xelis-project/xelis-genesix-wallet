import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/layout_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_textfield_widget.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  late Widget _widgetConfirmation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initConfirmationButton();
  }

  void _initConfirmationButton() {
    final loc = ref.read(appLocalizationsProvider);
    _widgetConfirmation = SizedBox(
      //width: 200,
      child: FilledButton(
        onPressed: _confirmNewPassword,
        child: Text(loc.confirm_button),
      ),
    );
  }

  void _confirmNewPassword() {
    if (_openFormKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final oldPassword =
          _openFormKey.currentState?.value['old_password'] as String;
      final newPassword1 =
          _openFormKey.currentState?.value['new_password1'] as String;
      final newPassword2 =
          _openFormKey.currentState?.value['new_password2'] as String;

      if (oldPassword == newPassword1) {
        _openFormKey.currentState?.fields['new_password1']
            ?.invalidate(loc.same_old_new_password_error);
      } else if (newPassword1 != newPassword2) {
        _openFormKey.currentState?.fields['new_password2']
            ?.invalidate(loc.not_match_new_password_error);
      } else {
        setState(() {
          _widgetConfirmation = const CircularProgressIndicator();
        });
        ref
            .read(walletStateProvider.notifier)
            .changePassword(oldPassword, newPassword1)
            .then((value) {
          setState(() {
            _widgetConfirmation = Column(
              children: [
                Icon(
                  Icons.check_rounded,
                  color: context.colors.primary,
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  loc.password_changed,
                  style: context.bodyMedium
                      ?.copyWith(color: context.colors.primary),
                ),
              ],
            );
          });
        }, onError: (_) {
          setState(() {
            _initConfirmationButton();
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Background(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.large),
        child: FormBuilder(
          key: _openFormKey,
          onChanged: () => _openFormKey.currentState!.save(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackHeader(title: loc.change_password),
              const SizedBox(height: Spaces.large),
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
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'new_password1',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: loc.new_password,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'new_password2',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: loc.confirm_password,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: AppDurations.animNormal),
                child: _widgetConfirmation,
              )
            ],
          ),
        ),
      ),
    );
  }
}
