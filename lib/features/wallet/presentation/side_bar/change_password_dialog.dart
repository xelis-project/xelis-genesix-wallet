import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_password_change_result.dart';

/// Drives a password change without coupling the dialog to a native wallet.
typedef WalletPasswordChanger =
    Future<WalletPasswordChangeResult> Function(
      String oldPassword,
      String newPassword,
    );

class ChangePasswordDialog extends ConsumerStatefulWidget {
  final Animation<double> animation;
  final WalletPasswordChanger? changePassword;

  const ChangePasswordDialog(this.animation, {this.changePassword, super.key});

  @override
  ConsumerState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmNewPasswordController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmNewPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return PopScope(
      canPop: !_isSaving,
      child: AppDialog.adaptive(
        clipBehavior: Clip.antiAlias,
        animation: widget.animation,
        title: Text(loc.change_password),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spaces.medium,
              children: [
                FTextFormField.password(
                  enabled: !_isSaving,
                  label: Text(loc.current_password),
                  control: FTextFieldControl.managed(
                    controller: _currentPasswordController,
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.cannot_be_empty;
                    }
                    return null;
                  },
                ),
                FTextFormField.password(
                  enabled: !_isSaving,
                  label: Text(loc.new_password),
                  control: FTextFieldControl.managed(
                    controller: _newPasswordController,
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.cannot_be_empty;
                    }
                    if (value == _currentPasswordController.text) {
                      return loc.same_old_new_password_error;
                    }
                    return null;
                  },
                ),
                FTextFormField.password(
                  enabled: !_isSaving,
                  label: Text(loc.confirm_new_password),
                  control: FTextFieldControl.managed(
                    controller: _confirmNewPasswordController,
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.cannot_be_empty;
                    }
                    if (value != _newPasswordController.text) {
                      return loc.not_match_new_password_error;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          AsyncFButton(
            isLoading: _isSaving,
            onPress: _onSave,
            child: Text(loc.save),
          ),
          FButton(
            variant: .outline,
            onPress: _isSaving ? null : () => context.pop(),
            child: Text(loc.cancel_button),
          ),
        ],
      ),
    );
  }

  void _onSave() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final changePassword =
          widget.changePassword ??
          ref.read(walletCommandsProvider).changePassword;
      final result = await changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      if (!mounted) return;

      final loc = ref.read(appLocalizationsProvider);
      final toast = ref.read(toastProvider.notifier);
      switch (result) {
        case WalletPasswordChangeSuccess():
          context.pop();
          toast.showEvent(description: loc.password_changed);
        case WalletPasswordChangeFailure(:final failure):
          toast.showFailure(title: loc.change_password, failure: failure);
        case WalletPasswordChangeNativeStateIndeterminate(:final failure):
          context.pop();
          toast.showFailure(
            title: loc.change_password,
            description: loc.password_change_native_state_indeterminate,
            failure: failure,
          );
        case WalletPasswordChangedBiometricDisabled(:final failure):
          context.pop();
          toast.showFailure(
            title: loc.change_password,
            description: loc.password_changed_biometric_disabled,
            failure: failure,
          );
        case WalletPasswordChangedBiometricCleanupFailed(:final failure):
          context.pop();
          toast.showFailure(
            title: loc.change_password,
            description: loc.password_changed_biometric_cleanup_failed,
            failure: failure,
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
