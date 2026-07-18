import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';
import 'package:genesix/features/authentication/domain/wallet_session_command_result.dart';
import 'package:genesix/features/authentication/presentation/components/current_network_indicator.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:go_router/go_router.dart';

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
  var _isCreating = false;

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
        suffixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction(
              icon: Icon(FLucideIcons.settings),
              onPress: _isCreating
                  ? null
                  : () => context.push(AppScreen.lightSettings.toPath),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AuthenticationStatusIndicators(),
          const SizedBox(height: Spaces.medium),
          Container(
            width: context.mediaWidth * 0.9,
            constraints: BoxConstraints(maxWidth: context.theme.breakpoints.sm),
            child: AppCard(
              clipBehavior: Clip.antiAlias,
              title: Text(loc.create_new_wallet),
              subtitle: Text(loc.create_new_wallet_subtitle),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: Spaces.medium),
                    FTextFormField(
                      enabled: !_isCreating,
                      control: .managed(controller: _nameController),
                      label: Text(loc.wallet_name),
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
                      enabled: !_isCreating,
                      control: .managed(controller: _passwordController),
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
                      enabled: !_isCreating,
                      control: .managed(controller: _confirmPasswordController),
                      label: Text(loc.confirm_your_password),
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
                    AsyncFButton(
                      isLoading: _isCreating,
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
    if (_isCreating || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isCreating = true);

    var keepCreating = false;
    try {
      final result = await ref
          .read(walletSessionCommandsProvider.notifier)
          .createWallet(
            _nameController.text.trim(),
            _passwordController.text.trim(),
          );

      if (result is WalletSessionCommandSuccess && mounted) {
        keepCreating = true;
        context.go(AuthAppScreen.home.toPath, extra: result.seedToReveal);
      }
    } finally {
      if (!keepCreating && mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
