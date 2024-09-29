import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/authentication/presentation/components/table_generation_progress_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/shared/widgets/components/password_textfield_widget.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key, this.isFromSeed = false});

  final bool isFromSeed;

  @override
  ConsumerState createState() => _CreateWalletWidgetState();
}

class _CreateWalletWidgetState extends ConsumerState<CreateWalletScreen> {
  final _createFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_createFormKey');

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
              .createWallet(walletName, password, createSeed);
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

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final wallets = ref.watch(walletsProvider);

    return Background(
      child: Scaffold(
        appBar: GenericAppBar(
            title: widget.isFromSeed
                ? loc.recover_from_mnemonic_phrase
                : loc.create_new_wallet),
        body: FormBuilder(
          key: _createFormKey,
          onChanged: () => _createFormKey.currentState!.save(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spaces.large, 0, Spaces.large, Spaces.large),
            children: [
              if (widget.isFromSeed) ...[
                Text(loc.seed, style: context.bodyLarge),
                const SizedBox(height: Spaces.small),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: FormBuilderTextField(
                    name: 'seed',
                    style: context.bodyLarge,
                    maxLines: null,
                    minLines: 5,
                    autocorrect: false,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: loc.paste_your_seed,
                      alignLabelWithHint: true,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minWordsCount(
                        24,
                        // errorText: loc.invalid_seed,
                        errorText: '${loc.seed_error_not_enough_words} (⩾24)',
                      ),
                      FormBuilderValidators.maxWordsCount(
                        25,
                        // errorText: loc.invalid_seed,
                        errorText: '${loc.seed_error_too_many_words} (⩽25)',
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: Spaces.large),
              ],
              Text(loc.wallet_name, style: context.bodyLarge),
              const SizedBox(height: Spaces.small),
              FormBuilderTextField(
                name: 'wallet_name',
                style: context.bodyLarge,
                autocorrect: false,
                decoration: InputDecoration(
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
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
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
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: loc.confirm_your_password,
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(height: Spaces.large),
              TextButton.icon(
                onPressed: () {
                  _createWallet();
                },
                icon: const Icon(Icons.wallet),
                label: Text(
                  widget.isFromSeed ? loc.recover_button : loc.create_button,
                  style: context.titleMedium!
                      .copyWith(color: context.colors.onPrimary),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
