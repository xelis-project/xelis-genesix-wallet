import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_textfield_widget.dart';

class PasswordDialog extends ConsumerStatefulWidget {
  final void Function(String password)? onEnter;
  final void Function()? onValid;

  const PasswordDialog({
    this.onEnter,
    this.onValid,
    super.key,
  });

  @override
  ConsumerState<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<PasswordDialog> {
  String? _passwordError;
  final FocusNode _passwordFocusNode = FocusNode();

  final _passwordFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_passwordFormKey');

  void _checkWalletPassword(BuildContext context) async {
    setState(() {
      _passwordError = null;
    });

    if (_passwordFormKey.currentState?.saveAndValidate() ?? false) {
      final password =
          _passwordFormKey.currentState?.value['password'] as String;

      final wallet = ref.read(walletStateProvider);
      try {
        context.loaderOverlay.show();
        await wallet.nativeWalletRepository!.isValidPassword(password);
        widget.onValid!();
        if (context.mounted) context.pop(); // hide the dialog
      } catch (e) {
        setState(() {
          _passwordError = 'Invalid password.';
        });
      }

      if (context.mounted) {
        context.loaderOverlay.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    FocusScope.of(context).requestFocus(_passwordFocusNode);

    return AlertDialog(
      scrollable: false,
      contentPadding: const EdgeInsets.all(10),
      actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      iconPadding: const EdgeInsets.all(10),
      content: Builder(
        builder: (BuildContext context) {
          return FormBuilder(
            key: _passwordFormKey,
            child: PasswordTextField(
              textField: FormBuilderTextField(
                name: 'password',
                autocorrect: false,
                focusNode: _passwordFocusNode,
                style: context.bodyLarge,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  fillColor: Colors.transparent,
                  hintText: loc.password,
                  errorText: _passwordError,
                  errorMaxLines: 2,
                ),
                onSubmitted: (value) {
                  if (widget.onEnter != null) {
                    widget.onEnter!(value!);
                  }

                  if (widget.onValid != null) {
                    _checkWalletPassword(context);
                  }
                },
                validator: FormBuilderValidators.required(),
              ),
            ),
          );
        },
      ),
    );
  }
}
