import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/authentication/presentation/components/seed_content_dialog.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
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
  const CreateWalletScreen({super.key});

  @override
  ConsumerState createState() => _CreateWalletWidgetState();
}

class _CreateWalletWidgetState extends ConsumerState<CreateWalletScreen> {
  final _createFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_createFormKey');

  bool _seedRequired = false;

  void _showTableGenerationProgressDialog(BuildContext context) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (_) => const TableGenerationProgressDialog(),
    );
  }

  Future<void> _loadSeedFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      var seed = await file.readAsString();
      _createFormKey.currentState?.patchValue({
        'seed': seed,
      });
    }
  }

  void _createWallet() async {
    //final loc = ref.watch(appLocalizationsProvider);

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
            ?.invalidate('does not match the password');
      } else if (walletName != null &&
          password != null &&
          password == confirmPassword) {
        try {
          if (!await ref
                  .read(authenticationProvider.notifier)
                  .isPrecomputedTablesExists() &&
              mounted) {
            _showTableGenerationProgressDialog(context);
          } else {
            context.loaderOverlay.show();
          }

          await ref
              .read(authenticationProvider.notifier)
              .createWallet(walletName, password, createSeed);

          var seed = await ref
              .read(walletStateProvider)
              .nativeWalletRepository!
              .getSeed();

          if (mounted) {
            showDialog<void>(
              context: context,
              builder: (context) {
                return SeedContentDialog(seed, ref);
              },
            );
          }
        } catch (e) {
          logger.severe('Creating wallet failed: $e');
          ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
        }

        if (mounted) {
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
        appBar: GenericAppBar(title: loc.create_new_wallet),
        body: FormBuilder(
          key: _createFormKey,
          onChanged: () => _createFormKey.currentState!.save(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Spaces.large, 0, Spaces.large, Spaces.large),
            children: [
              FormBuilderSwitch(
                name: 'seed_switch',
                initialValue: _seedRequired,
                title: Text(loc.create_from_seed, style: context.bodyLarge),
                onChanged: (value) {
                  setState(() {
                    _seedRequired = value!;
                  });
                },
              ),
              const SizedBox(height: Spaces.small),
              const Divider(),
              Visibility(
                visible: _seedRequired,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          labelText: loc.seed,
                          alignLabelWithHint: true,
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          // TODO: add better seed validator
                          FormBuilderValidators.match(
                            '(?:[a-zA-Z]+ ){24}[a-zA-Z]+',
                            errorText: loc.invalid_seed,
                          ),
                          // FormBuilderValidators.minWordsCount(25),
                          // FormBuilderValidators.maxWordsCount(25),
                        ]),
                      ),
                    ),
                    const SizedBox(height: Spaces.small),
                    TextButton.icon(
                      onPressed: () {
                        _loadSeedFromFile();
                      },
                      icon: const Icon(
                        Icons.file_open_outlined,
                        size: 18,
                      ),
                      label: Text(
                        loc.load_from_file,
                        style: context.titleMedium!.copyWith(
                            color: context.colors.onPrimary, fontSize: 14),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const SizedBox(height: Spaces.small),
              Text(loc.wallet_name, style: context.bodyLarge),
              const SizedBox(height: Spaces.small),
              FormBuilderTextField(
                name: 'wallet_name',
                style: context.bodyLarge,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: loc.wallet_name,
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
              const SizedBox(height: Spaces.small),
              Text(loc.password, style: context.bodyLarge),
              const SizedBox(height: Spaces.small),
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'password',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: loc.password,
                  ),
                ),
              ),
              const SizedBox(height: Spaces.small),
              Text(loc.confirm_password, style: context.bodyLarge),
              const SizedBox(height: Spaces.small),
              PasswordTextField(
                textField: FormBuilderTextField(
                  name: 'confirm_password',
                  style: context.bodyLarge,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: loc.confirm_password,
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              TextButton.icon(
                onPressed: () {
                  _createWallet();
                },
                icon: const Icon(Icons.wallet),
                label: Text(
                  loc.create,
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
