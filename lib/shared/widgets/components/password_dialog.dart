import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
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

  final _passwordFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_passwordFormKey',
  );

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _checkWalletPassword(BuildContext context) async {
    final password = _passwordFormKey.currentState?.value['password'] as String;

    final wallet = ref.read(walletStateProvider);
    try {
      context.loaderOverlay.show();

      // check if password is valid
      await wallet.nativeWalletRepository!.isValidPassword(password);

      // call onValid callback
      widget.onValid!();

      // unlock biometric auth if locked
      if (ref.read(biometricAuthProvider) ==
          BiometricAuthProviderStatus.locked) {
        ref
            .read(biometricAuthProvider.notifier)
            .updateStatus(BiometricAuthProviderStatus.ready);
      }

      if (widget.closeOnValid == true && context.mounted) {
        context.pop(); // hide the dialog
      }
    } catch (e) {
      final loc = ref.read(appLocalizationsProvider);
      setState(() {
        _passwordError = loc.invalid_password_error;
      });
    }

    if (context.mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return GenericDialog(
      scrollable: false,
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  loc.authentication.capitalize(),
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.authentication_message,
            style: context.bodyMedium?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.large),
          FormBuilder(
            key: _passwordFormKey,
            child: PasswordTextField(
              textField: FormBuilderTextField(
                name: 'password',
                autocorrect: false,
                autofocus: true,
                focusNode: _focusNode,
                style: context.bodyLarge,
                decoration: context.textInputDecoration.copyWith(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: loc.password,
                  errorText: _passwordError,
                ),
                onChanged: (_) {
                  setState(() {
                    _passwordError = null;
                  });
                  // workaround to reset the error message when the user modifies the field
                  final hasError = _passwordFormKey
                      .currentState
                      ?.fields['password']
                      ?.hasError;
                  if (hasError ?? false) {
                    _passwordFormKey.currentState?.fields['password']?.reset();
                  }
                },
                onSubmitted: (value) {
                  if (_passwordFormKey.currentState?.saveAndValidate() ??
                      false) {
                    if (widget.onEnter != null) {
                      widget.onEnter!(value!);
                    }

                    if (widget.onValid != null) {
                      _checkWalletPassword(context);
                    }

                    _focusNode.unfocus();
                  }
                },
                validator: FormBuilderValidators.required(
                  errorText: loc.field_required_error,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            if (_passwordFormKey.currentState?.saveAndValidate() ?? false) {
              if (widget.onEnter != null) {
                widget.onEnter!(
                  _passwordFormKey.currentState!.value['password'] as String,
                );
              }

              if (widget.onValid != null) {
                _checkWalletPassword(context);
              }

              _focusNode.unfocus();
            }
          },
          label: Text(loc.next),
          icon: Icon(Icons.arrow_forward_rounded, size: 18),
        ),
      ],
    );
  }
}
