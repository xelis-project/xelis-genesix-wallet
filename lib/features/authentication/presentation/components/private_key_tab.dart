import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:loader_overlay/loader_overlay.dart';

class PrivateKeyTab extends ConsumerStatefulWidget {
  const PrivateKeyTab({super.key});

  @override
  ConsumerState<PrivateKeyTab> createState() => _PrivateKeyTabState();
}

class _PrivateKeyTabState extends ConsumerState<PrivateKeyTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _privateKeyController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return FCard(
      subtitle: const Text(
        'To import your wallet, please enter your private key. It should be a 64-character hexadecimal string.',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: Spaces.medium),
            FTextFormField.multiline(
              controller: _privateKeyController,
              label: const Text('Private Key'),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your private key';
                }
                // Validate the private key format (64 hexadecimal characters)
                final regex = RegExp(r'^[0-9a-fA-F]{64}$');
                if (!regex.hasMatch(value)) {
                  return 'Private key must be a 64-character hexadecimal string';
                }
                return null;
              },
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              controller: _nameController,
              label: Text('Name'),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a wallet name';
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              controller: _passwordController,
              label: Text(loc.password.capitalize()),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              controller: _confirmPasswordController,
              label: Text(loc.confirm_password.capitalizeAll()),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.large),
            FButton(onPress: _createWallet, child: Text(loc.recover_button)),
          ],
        ),
      ),
    );
  }

  void _createWallet() async {
    if (_formKey.currentState?.validate() ?? false) {
      context.loaderOverlay.show();

      await ref
          .read(authenticationProvider.notifier)
          .createWallet(
            _nameController.text.trim(),
            _passwordController.text,
            privateKey: _privateKeyController.text,
          );

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
