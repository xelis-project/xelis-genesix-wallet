import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';

class PasswordDialog extends ConsumerStatefulWidget {
  final void Function(String password)? onEnter;
  final void Function()? onValid;
  final bool closeOnValid;
  final Animation<double> animation;

  const PasswordDialog(
    this.animation, {
    this.onEnter,
    this.onValid,
    this.closeOnValid = true,
    super.key,
  });

  @override
  ConsumerState<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<PasswordDialog> {
  late FocusNode _focusNode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus(); // Automatically focus the password field
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkWalletPassword(BuildContext context, String password) async {
    final wallet = ref.read(walletStateProvider);
    try {
      context.loaderOverlay.show();

      // check if password is valid
      await wallet.nativeWalletRepository!.isValidPassword(password);

      // call onValid callback
      widget.onValid!();

      if (widget.closeOnValid == true && context.mounted) {
        context.pop(); // hide the dialog
      }
    } catch (e) {
      ref.read(toastProvider.notifier).showError(description: e.toString());
    }

    if (context.mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return FDialog(
      animation: widget.animation,
      direction: Axis.horizontal,
      title: Text(loc.authentication.capitalize()),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.authentication_message),
          const SizedBox(height: Spaces.large),
          Form(
            key: _formKey,
            child: FTextFormField.password(
              control: .managed(controller: _passwordController),
              focusNode: _focusNode,
              label: Text(loc.password.capitalize()),
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
              onSubmit: (value) {
                if (_formKey.currentState?.validate() ?? false) {
                  if (widget.onEnter != null) {
                    widget.onEnter!(value);
                  }

                  if (widget.onValid != null) {
                    _checkWalletPassword(context, value);
                  }

                  _focusNode.unfocus();
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          variant: .outline,
          onPress: () => context.pop(),
          child: Text(loc.cancel_button),
        ),
        FButton(
          onPress: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (widget.onEnter != null) {
                widget.onEnter!(_passwordController.text);
              }

              if (widget.onValid != null) {
                _checkWalletPassword(context, _passwordController.text);
              }

              _focusNode.unfocus();
            }
          },
          child: Text(loc.continue_button),
        ),
      ],
    );
  }
}
