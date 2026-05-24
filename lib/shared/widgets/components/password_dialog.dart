import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class PasswordDialog extends ConsumerStatefulWidget {
  final FutureOr<void> Function(String password)? onEnter;
  final FutureOr<void> Function()? onValid;
  final bool closeOnValid;
  final Animation<double> animation;

  const PasswordDialog(
    this.animation, {
    this.onEnter,
    this.onValid,
    this.closeOnValid = true,
    super.key,
  }) : assert(
         onEnter != null || onValid != null,
         'PasswordDialog requires either onEnter or onValid.',
       );

  @override
  ConsumerState<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<PasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var _password = '';

  Future<void> _submit(String password) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    await widget.onEnter?.call(password);

    if (widget.onValid != null && mounted) {
      await _checkWalletPassword(password);
    }
  }

  Future<void> _checkWalletPassword(String password) async {
    final wallet = ref.read(activeWalletRepositoryProvider);
    final loc = ref.read(appLocalizationsProvider);

    try {
      context.loaderOverlay.show();

      if (wallet == null) {
        throw Exception(loc.oups);
      }

      await wallet.isValidPassword(password);
      await widget.onValid?.call();

      if (widget.closeOnValid && mounted) {
        context.pop();
      }
    } catch (e) {
      ref.read(toastProvider.notifier).showError(description: e.toString());
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return FDialog.adaptive(
      clipBehavior: Clip.antiAlias,
      animation: widget.animation,
      title: Text(loc.authentication.capitalize()),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.authentication_message),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
            child: Form(
              key: _formKey,
              child: FTextFormField.password(
                control: .managed(onChange: (value) => _password = value.text),
                autofocus: true,
                label: Text(loc.password.capitalize()),
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.field_required_error;
                  }
                  return null;
                },
                onSubmit: _submit,
              ),
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          onPress: () => _submit(_password),
          child: Text(loc.continue_button),
        ),
        FButton(
          variant: .outline,
          onPress: () => context.pop(),
          child: Text(loc.cancel_button),
        ),
      ],
    );
  }
}
