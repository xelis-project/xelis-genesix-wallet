import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return FScaffold(
      header: FHeader.nested(
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FHeaderAction.back(onPress: context.pop),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: context.theme.breakpoints.sm),
            child: FCard(
              title: const Text('Create New Wallet'),
              subtitle: const Text(
                'Please enter a name and password for your new wallet.',
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: Spaces.medium),
                    FTextFormField(
                      controller: _nameController,
                      label: Text('Name'),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().isEmpty) {
                          return loc.field_required_error;
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
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().isEmpty) {
                          return loc.field_required_error;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spaces.medium),
                    FTextFormField(
                      controller: _confirmPasswordController,
                      label: Text('Confirm Password'),
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().isEmpty) {
                          return loc.field_required_error;
                        }
                        if (value.trim() != _passwordController.text.trim()) {
                          return loc.password_not_match;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spaces.large),
                    FButton(
                      onPress: _createWallet,
                      child: Text(loc.create_button),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            _passwordController.text.trim(),
          );

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
