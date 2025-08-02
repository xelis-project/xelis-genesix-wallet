import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

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
      direction: Axis.horizontal,
      // title: Text(loc.change_password),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FTextFormField(
              label: Text('Current Password'),
              controller: _currentPasswordController,
              autovalidateMode: AutovalidateMode.onUnfocus,
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              label: Text('New Password'),
              controller: _newPasswordController,
              autovalidateMode: AutovalidateMode.onUnfocus,
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'cannot be empty';
                }
                if (value.trim() == _currentPasswordController.text) {
                  return loc.same_old_new_password_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              label: Text('Confirm New Password'),
              controller: _confirmNewPasswordController,
              autovalidateMode: AutovalidateMode.onUnfocus,
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'cannot be empty';
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
          style: FButtonStyle.outline(),
          onPress: () {
            context.pop();
          },
          child: Text(loc.cancel_button),
        ),
        FButton(onPress: _onSave, child: Text(loc.save)),
      ],
    );
  }

  void _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        context.loaderOverlay.show();

        await ref
            .read(walletStateProvider.notifier)
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
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
