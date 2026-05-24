import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

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
    return FDialog(
      clipBehavior: Clip.antiAlias,
      direction: Axis.horizontal,
      // title: Text(loc.change_password),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: Spaces.medium),
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
                if (value.trim() == _currentPasswordController.text) {
                  return loc.same_old_new_password_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
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
                if (value.trim() != _newPasswordController.text) {
                  return loc.not_match_new_password_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
          ],
        ),
      ),
      actions: [
        FButton(
          variant: .outline,
          onPress: _isSaving ? null : () => context.pop(),
          child: Text(loc.cancel_button),
        ),
        AsyncFButton(
          isLoading: _isSaving,
          onPress: _onSave,
          child: Text(loc.save),
        ),
      ],
    );
  }

  void _onSave() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(walletCommandsProvider)
          .changePassword(
            _currentPasswordController.text.trim(),
            _newPasswordController.text.trim(),
          );

      if (mounted) {
        context.pop();
      }

      ref
          .read(toastProvider.notifier)
          .showEvent(
            description: ref.read(appLocalizationsProvider).password_changed,
          );
    } catch (e) {
      ref.read(toastProvider.notifier).showError(description: e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
