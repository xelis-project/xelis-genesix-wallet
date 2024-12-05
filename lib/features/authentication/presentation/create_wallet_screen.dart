import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/authentication/domain/create_wallet_type_enum.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/authentication/presentation/components/table_generation_progress_dialog.dart';
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
  final _createFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_createFormKey');

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
      CreateWalletType.fromPrivateKey => loc.recover_from_seed_message,
      CreateWalletType.fromSeed => loc.recover_from_private_key_message,
    };

    final recoverWidget = switch (widget.type) {
      CreateWalletType.newWallet => SizedBox.shrink(),
      CreateWalletType.fromPrivateKey => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.private_key,
              style: context.bodyLarge,
            ),
            const SizedBox(height: Spaces.small),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: FormBuilderTextField(
                name: 'private key',
                focusNode: _focusNodePrivateKey,
                style: context.bodyLarge,
                autocorrect: false,
                keyboardType: TextInputType.text,
                decoration: context.textInputDecoration.copyWith(
                  labelText: loc.private_key_inputfield,
                  alignLabelWithHint: true,
                ),
                maxLength: 64,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    Text(
                  '$currentLength/$maxLength',
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.equalLength(64,
                      errorText: loc.private_key_error_lenght),
                  FormBuilderValidators.match(RegExp(r'^[0-9a-fA-F]+$'),
                      errorText: loc.private_key_error_hexa),
                ]),
              ),
            ),
            const SizedBox(height: Spaces.large),
          ],
        ),
      CreateWalletType.fromSeed => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.seed,
              style: context.bodyLarge,
            ),
            const SizedBox(height: Spaces.small),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: FormBuilderTextField(
                name: 'seed',
                focusNode: _focusNodeSeed,
                style: context.bodyLarge,
                maxLines: null,
                minLines: 5,
                autocorrect: false,
                keyboardType: TextInputType.multiline,
                decoration: context.textInputDecoration.copyWith(
                  labelText: loc.paste_your_seed,
                  alignLabelWithHint: true,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minWordsCount(
                    24,
                    errorText: loc.seed_error_wrong_words_count,
                  ),
                  FormBuilderValidators.maxWordsCount(
                    25,
                    errorText: loc.seed_error_wrong_words_count,
                  ),
                ]),
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

    return CustomScaffold(
      appBar: GenericAppBar(title: title),
      body: FormBuilder(
        key: _createFormKey,
        onChanged: () => _createFormKey.currentState!.save(),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              Spaces.large, Spaces.none, Spaces.large, Spaces.large),
          children: [
            const SizedBox(height: Spaces.large),
            Text(
              message,
              style: context.titleSmall
                  ?.copyWith(color: context.moreColors.mutedColor),
            ),
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
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
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
                validator: FormBuilderValidators.required(),
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
                validator: FormBuilderValidators.required(),
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
                      style: context.titleMedium!
                          .copyWith(color: context.colors.onPrimary),
                    ),
                  ),
                ),
                if (context.isWideScreen) const Spacer(),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showTableGenerationProgressDialog(BuildContext context) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (_) => const TableGenerationProgressDialog(),
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
      final createSeed = _createFormKey.currentState?.value['seed'] as String?;

      if (password != confirmPassword) {
        _createFormKey.currentState?.fields['confirm_password']
            ?.invalidate(loc.password_not_match);
      } else if (walletName != null &&
          password != null &&
          password == confirmPassword) {
        _unfocusNodes();

        try {
          if (!await ref
                  .read(authenticationProvider.notifier)
                  .isPrecomputedTablesExists() &&
              mounted) {
            talker
                .info('Creating wallet: show table generation progress dialog');
            _showTableGenerationProgressDialog(context);
          } else {
            talker.info('Creating wallet: show loader overlay');
            context.loaderOverlay.show();
          }

          await ref
              .read(authenticationProvider.notifier)
              .createWallet(walletName, password, createSeed?.trim());
        } catch (e) {
          talker.critical('Creating wallet failed: $e');
          ref
              .read(snackBarMessengerProvider.notifier)
              .showError(loc.error_when_creating_wallet);
          if (mounted) {
            // Dismiss TableGenerationProgressDialog if error occurs
            context.pop();
          }
        }

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
