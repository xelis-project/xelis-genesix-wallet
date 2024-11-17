import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/password_textfield_widget.dart';
import 'package:intl/intl.dart';

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

    if (context.mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return GenericDialog(
      scrollable: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: Spaces.medium, top: Spaces.large),
            child: Text(
              toBeginningOfSentenceCase(loc.authentication),
              style: context.titleLarge,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(right: Spaces.small, top: Spaces.small),
            child: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.authentication_message,
            style: context.bodyMedium
                ?.copyWith(color: context.moreColors.mutedColor),
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
                validator: FormBuilderValidators.required(),
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
                    _passwordFormKey.currentState!.value['password'] as String);
              }

              if (widget.onValid != null) {
                _checkWalletPassword(context);
              }

              _focusNode.unfocus();
            }
          },
          label: Text(
            loc.next,
          ),
          icon: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
          ),
        ),
      ],
    );
  }
}
