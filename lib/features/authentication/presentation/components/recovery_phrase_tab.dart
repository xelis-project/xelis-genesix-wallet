import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';
import 'package:genesix/features/authentication/domain/wallet_session_command_result.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class RecoveryPhraseTab extends ConsumerStatefulWidget {
  const RecoveryPhraseTab({super.key});

  @override
  ConsumerState createState() => _RecoveryPhraseTabState();
}

class _RecoveryPhraseTabState extends ConsumerState<RecoveryPhraseTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _recoveryPhraseController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _recoveryPhraseController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return FCard(
      subtitle: Text(loc.recover_from_recovery_phrase),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: Spaces.medium),
            FTextFormField.multiline(
              control: .managed(controller: _recoveryPhraseController),
              label: Text(loc.recovery_phrase),
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                final words = value.trim().split(RegExp(r'\s+'));
                if (words.length < 24 || words.length > 25) {
                  return loc.recovery_phrase_word_count_error;
                }
                return null;
              },
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(controller: _nameController),
              label: Text(loc.wallet_name),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(controller: _passwordController),
              label: Text(loc.password.capitalize()),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(controller: _confirmPasswordController),
              label: Text(loc.confirm_password.capitalizeAll()),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                if (value.trim() != _passwordController.text.trim()) {
                  return loc.password_not_match;
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

      final result = await ref
          .read(walletSessionCommandsProvider.notifier)
          .createWallet(
            _nameController.text.trim(),
            _passwordController.text.trim(),
            seed: _recoveryPhraseController.text.trim(),
          );

      if (result is WalletSessionCommandSuccess && mounted) {
        context.go(AuthAppScreen.home.toPath, extra: result.seedToReveal);
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
