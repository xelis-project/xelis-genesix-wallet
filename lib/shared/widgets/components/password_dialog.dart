import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/password_textfield_widget.dart';

class PasswordDialog extends ConsumerStatefulWidget {
  final void Function(String password)? onEnter;
  final void Function()? onValid;
  final bool closeOnValid;

  const PasswordDialog({
    this.onEnter,
    this.onValid,
    this.closeOnValid = true,
    super.key,
  });

  @override
  ConsumerState<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<PasswordDialog> {
  String? _passwordError;

  final _passwordFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_passwordFormKey');

  void _checkWalletPassword(BuildContext context) async {
    setState(() {
      _passwordError = null;
    });

    final password = _passwordFormKey.currentState?.value['password'] as String;

    final wallet = ref.read(walletStateProvider);
    try {
      context.loaderOverlay.show();
      await wallet.nativeWalletRepository!.isValidPassword(password);
      widget.onValid!();
      if (widget.closeOnValid == true && context.mounted) {
        context.pop(); // hide the dialog
      }
    } catch (e) {
      final loc = ref.read(appLocalizationsProvider);
      setState(() {
        _passwordError = loc.invalid_password_error;
      });
    }

    if (context.mounted) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return AlertDialog(
      scrollable: false,
      contentPadding: const EdgeInsets.all(Spaces.small),
      //iconPadding: const EdgeInsets.all(Spaces.small),
      content: FormBuilder(
        key: _passwordFormKey,
        child: PasswordTextField(
          textField: FormBuilderTextField(
            name: 'password',
            autocorrect: false,
            autofocus: true,
            style: context.bodyLarge,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              fillColor: Colors.transparent,
              hintText: loc.password,
              errorText: _passwordError,
              errorMaxLines: 2,
            ),
            onSubmitted: (value) {
              if (_passwordFormKey.currentState?.saveAndValidate() ?? false) {
                if (widget.onEnter != null) {
                  widget.onEnter!(value!);
                }

                if (widget.onValid != null) {
                  _checkWalletPassword(context);
                }
              }
            },
            validator: FormBuilderValidators.required(),
          ),
        ),
      ),
    );
  }
}
