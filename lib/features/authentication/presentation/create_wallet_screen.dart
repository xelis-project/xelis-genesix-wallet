import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/authentication/domain/create_wallet_type_enum.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/shared/widgets/components/password_textfield_widget.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key, required this.type});

  final CreateWalletType type;

  @override
  ConsumerState createState() => _CreateWalletWidgetState();
}

class _CreateWalletWidgetState extends ConsumerState<CreateWalletScreen> {
  final _createFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_createFormKey',
  );

  late FocusNode _focusNodeSeed;
  late FocusNode _focusNodePrivateKey;
  late FocusNode _focusNodeName;
  late FocusNode _focusNodePassword;
  late FocusNode _focusNodeConfirmPassword;

  @override
  void initState() {
    super.initState();
    _focusNodeSeed = FocusNode();
    _focusNodePrivateKey = FocusNode();
    _focusNodeName = FocusNode();
    _focusNodePassword = FocusNode();
    _focusNodeConfirmPassword = FocusNode();
  }

  @override
  dispose() {
    _focusNodeSeed.dispose();
    _focusNodePrivateKey.dispose();
    _focusNodeName.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final wallets = ref.watch(walletsProvider);

    final title = switch (widget.type) {
      CreateWalletType.newWallet => loc.new_wallet,
      CreateWalletType.fromPrivateKey => loc.recover_wallet,
      CreateWalletType.fromSeed => loc.recover_wallet,
    };

    final message = switch (widget.type) {
      CreateWalletType.newWallet => loc.create_new_wallet_message,
      CreateWalletType.fromPrivateKey => loc.recover_from_private_key_message,
      CreateWalletType.fromSeed => '',
    };

    final recoverWidget = switch (widget.type) {
      CreateWalletType.newWallet => SizedBox.shrink(),
      CreateWalletType.fromPrivateKey => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.private_key, style: context.bodyLarge),
          const SizedBox(height: Spaces.small),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: FormBuilderTextField(
              name: 'private_key',
              focusNode: _focusNodePrivateKey,
              style: context.bodyLarge,
              autocorrect: false,
              keyboardType: TextInputType.text,
              decoration: context.textInputDecoration.copyWith(
                labelText: loc.private_key_inputfield,
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                // workaround to reset the error message when the user modifies the field
                final hasError =
                    _createFormKey
                        .currentState
                        ?.fields['private_key']
                        ?.hasError;
                if (hasError ?? false) {
                  _createFormKey.currentState?.fields['private_key']?.reset();
                }
              },
              maxLength: 64,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => Text('$currentLength/$maxLength'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: loc.field_required_error,
                ),
                FormBuilderValidators.equalLength(
                  64,
                  errorText: loc.private_key_error_lenght,
                ),
                FormBuilderValidators.match(
                  RegExp(r'^[0-9a-fA-F]+$'),
                  errorText: loc.private_key_error_hexa,
                ),
              ]),
            ),
          ),
          const SizedBox(height: Spaces.large),
        ],
      ),
      CreateWalletType.fromSeed => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.your_recovery_phrase, style: context.bodyLarge),
          const SizedBox(height: Spaces.small),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: SelectableText(
                (GoRouterState.of(context).extra! as List<String>).join(' '),
                style: context.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: Spaces.large),
        ],
      ),
    };

    final buttonLabel = switch (widget.type) {
      CreateWalletType.newWallet => loc.create_button,
      CreateWalletType.fromPrivateKey => loc.recover_button,
      CreateWalletType.fromSeed => loc.recover_button,
    };

    final isFromSeed = widget.type == CreateWalletType.fromSeed;

    return CustomScaffold(
      appBar:
          isFromSeed
              ? GenericAppBar(
                title: title,
                implyLeading: true,
                onBack: () {
                  context.go(AppScreen.openWallet.toPath);
                },
              )
              : GenericAppBar(title: title),
      body: FormBuilder(
        key: _createFormKey,
        onChanged: () => _createFormKey.currentState!.save(),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            Spaces.large,
            Spaces.none,
            Spaces.large,
            Spaces.large,
          ),
          children: [
            if (!isFromSeed) ...[
              const SizedBox(height: Spaces.large),
              Text(
                message,
                style: context.titleSmall?.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
            ],
            const SizedBox(height: Spaces.extraLarge),
            recoverWidget,
            Text(loc.wallet_name, style: context.bodyLarge),
            const SizedBox(height: Spaces.small),
            FormBuilderTextField(
              name: 'wallet_name',
              focusNode: _focusNodeName,
              style: context.bodyLarge,
              autocorrect: false,
              decoration: context.textInputDecoration.copyWith(
                labelText: loc.set_a_wallet_name,
              ),
              onChanged: (value) {
                // workaround to reset the error message when the user modifies the field
                final hasError =
                    _createFormKey
                        .currentState
                        ?.fields['wallet_name']
                        ?.hasError;
                if (hasError ?? false) {
                  _createFormKey.currentState?.fields['wallet_name']?.reset();
                }
              },
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: loc.field_required_error,
                ),
                FormBuilderValidators.minLength(1),
                FormBuilderValidators.maxLength(64),
                (val) {
                  // check if this wallet name already exists.
                  if (wallets.containsKey(val)) {
                    return loc.wallet_name_already_exists;
                  }
                  return null;
                },
              ]),
            ),
            const SizedBox(height: Spaces.large),
            Text(loc.password, style: context.bodyLarge),
            const SizedBox(height: Spaces.small),
            PasswordTextField(
              textField: FormBuilderTextField(
                name: 'password',
                focusNode: _focusNodePassword,
                style: context.bodyLarge,
                autocorrect: false,
                decoration: context.textInputDecoration.copyWith(
                  labelText: loc.choose_strong_password,
                ),
                onChanged: (value) {
                  // workaround to reset the error message when the user modifies the field
                  final hasError =
                      _createFormKey.currentState?.fields['password']?.hasError;
                  if (hasError ?? false) {
                    _createFormKey.currentState?.fields['password']?.reset();
                  }
                },
                validator: FormBuilderValidators.required(
                  errorText: loc.field_required_error,
                ),
              ),
            ),
            const SizedBox(height: Spaces.large),
            Text(loc.confirm_password, style: context.bodyLarge),
            const SizedBox(height: Spaces.small),
            PasswordTextField(
              textField: FormBuilderTextField(
                name: 'confirm_password',
                focusNode: _focusNodeConfirmPassword,
                style: context.bodyLarge,
                autocorrect: false,
                decoration: context.textInputDecoration.copyWith(
                  labelText: loc.confirm_your_password,
                ),
                onChanged: (value) {
                  // workaround to reset the error message when the user modifies the field
                  final hasError =
                      _createFormKey
                          .currentState
                          ?.fields['confirm_password']
                          ?.hasError;
                  if (hasError ?? false) {
                    _createFormKey.currentState?.fields['confirm_password']
                        ?.reset();
                  }
                },
                validator: FormBuilderValidators.required(
                  errorText: loc.field_required_error,
                ),
              ),
            ),
            const SizedBox(height: Spaces.extraLarge),
            Row(
              children: [
                if (context.isWideScreen) const Spacer(),
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    onPressed: () {
                      _createWallet();
                    },
                    icon: const Icon(Icons.wallet),
                    label: Text(
                      buttonLabel,
                      style: context.titleMedium!.copyWith(
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ),
                if (context.isWideScreen) const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createWallet() async {
    final loc = ref.read(appLocalizationsProvider);

    if (_createFormKey.currentState?.saveAndValidate() ?? false) {
      final walletName =
          _createFormKey.currentState?.value['wallet_name'] as String?;
      final password =
          _createFormKey.currentState?.value['password'] as String?;
      final confirmPassword =
          _createFormKey.currentState?.value['confirm_password'] as String?;
      final privateKey =
          _createFormKey.currentState?.value['private_key'] as String?;
      final createSeed = (GoRouterState.of(context).extra as List<String>?)
          ?.join(' ');

      if (password != confirmPassword) {
        _createFormKey.currentState?.fields['confirm_password']?.invalidate(
          loc.password_not_match,
        );
      } else if (walletName != null &&
          password != null &&
          password == confirmPassword) {
        _unfocusNodes();

        context.loaderOverlay.show();

        await ref
            .read(authenticationProvider.notifier)
            .createWallet(walletName, password, createSeed, privateKey);

        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
      }
    }
  }

  void _unfocusNodes() {
    _focusNodeSeed.unfocus();
    _focusNodeName.unfocus();
    _focusNodePassword.unfocus();
    _focusNodeConfirmPassword.unfocus();
  }
}
