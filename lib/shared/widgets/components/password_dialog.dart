import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';

class PasswordDialog extends ConsumerStatefulWidget {
  final void Function() onValid;

  const PasswordDialog({
    required this.onValid,
    super.key,
  });

  @override
  ConsumerState<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<PasswordDialog> {
  bool _hidePassword = true;
  String? _passwordError;

  final _passwordFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_passwordFormKey');

  void _checkPassword(BuildContext context) async {
    setState(() {
      _passwordError = null;
    });

    if (_passwordFormKey.currentState?.saveAndValidate() ?? false) {
      final password =
          _passwordFormKey.currentState?.value['password'] as String;

      final wallet = ref.read(walletStateProvider);
      try {
        await wallet.nativeWalletRepository!.isValidPassword(password);
        widget.onValid();
        if (context.mounted) context.pop();
      } catch (e) {
        setState(() {
          _passwordError = 'Invalid password.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return AlertDialog(
      scrollable: false,
      content: Builder(
        builder: (BuildContext context) {
          final width = context.mediaSize.width * 0.8;

          return SizedBox(
            width: isDesktopDevice ? width : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animFast),
              child: FormBuilder(
                key: _passwordFormKey,
                child: FormBuilderTextField(
                  name: 'password',
                  obscureText: _hidePassword,
                  autocorrect: false,
                  style: context.bodyLarge,
                  decoration: InputDecoration(
                    labelText: loc.password,
                    errorText: _passwordError,
                    errorMaxLines: 2,
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
              ),
            ),
          );
        },
      ),
      actions: [
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(loc.cancel_button),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: FilledButton(
            onPressed: () => _checkPassword(context),
            child: Text(loc.confirm_button),
          ),
        ),
      ],
    );
  }
}
