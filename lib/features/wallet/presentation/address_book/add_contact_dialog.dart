import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:go_router/go_router.dart';

class AddContactDialog extends ConsumerStatefulWidget {
  const AddContactDialog({super.key, this.address});

  final String? address;

  @override
  ConsumerState<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends ConsumerState<AddContactDialog> {
  final _formKey = GlobalKey<FormBuilderState>(
    debugLabel: '_addContactFormKey',
  );

  late FocusNode _focusNodeName;
  late FocusNode _focusNodeAddress;

  @override
  void initState() {
    super.initState();
    _focusNodeName = FocusNode();
    _focusNodeAddress = FocusNode();
    widget.address == null
        ? _focusNodeAddress.requestFocus()
        : _focusNodeName.requestFocus();
  }

  @override
  void dispose() {
    _focusNodeName.dispose();
    _focusNodeAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return GenericDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  'New contact',
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.address != null) ...[
              Text(
                loc.address,
                style: context.titleSmall?.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              SelectableText(widget.address!, style: context.bodyLarge),
              const SizedBox(height: Spaces.large),
            ],
            FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.address == null) ...[
                    Text(
                      loc.address,
                      style: context.titleSmall?.copyWith(
                        color: context.moreColors.mutedColor,
                      ),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    FormBuilderTextField(
                      name: 'address',
                      focusNode: _focusNodeAddress,
                      style: context.bodyLarge,
                      autocorrect: false,
                      keyboardType: TextInputType.text,
                      decoration: context.textInputDecoration,
                      onChanged: (value) {
                        // workaround to reset the error message when the user modifies the field
                        final hasError =
                            _formKey.currentState?.fields['address']?.hasError;
                        if (hasError ?? false) {
                          _formKey.currentState?.fields['address']?.reset();
                        }
                      },
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: loc.field_required_error,
                        ),
                        _addressValidator,
                      ]),
                    ),
                    const SizedBox(height: Spaces.large),
                  ],
                  Text(
                    loc.name.capitalize(),
                    style: context.titleSmall?.copyWith(
                      color: context.moreColors.mutedColor,
                    ),
                  ),
                  const SizedBox(height: Spaces.extraSmall),
                  FormBuilderTextField(
                    name: 'name',
                    focusNode: _focusNodeName,
                    style: context.bodyLarge,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    decoration: context.textInputDecoration,
                    onChanged: (value) {
                      // workaround to reset the error message when the user modifies the field
                      final hasError =
                          _formKey.currentState?.fields['name']?.hasError;
                      if (hasError ?? false) {
                        _formKey.currentState?.fields['name']?.reset();
                      }
                    },
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: loc.field_required_error,
                      ),
                      FormBuilderValidators.minLength(
                        3,
                        errorText: 'Name must be at least 3 characters',
                      ),
                      FormBuilderValidators.maxLength(
                        128,
                        errorText: 'maximum length is 128 characters',
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: TextButton(onPressed: _saveName, child: Text('Add')),
        ),
      ],
    );
  }

  Future<void> _saveName() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      _focusNodeName.unfocus();
      _focusNodeAddress.unfocus();
      final name = _formKey.currentState?.fields['name']?.value as String?;
      final address =
          _formKey.currentState?.fields['address']?.value as String?;
      if (widget.address != null && name != null) {
        ref
            .read(addressBookProvider.notifier)
            .upsert(widget.address!, name.trim(), null);
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(
              '$name added to address book',
              duration: Duration(seconds: 2),
            );
      } else if (address != null && name != null) {
        if (await ref
            .read(addressBookProvider.notifier)
            .exists(address.trim())) {
          _formKey.currentState?.fields['address']?.invalidate(
            'Contact already exists',
          );
          return;
        }

        try {
          ref
              .read(addressBookProvider.notifier)
              .upsert(address.trim(), name.trim(), null);
          ref
              .read(snackBarQueueProvider.notifier)
              .showInfo(
                '$name added to address book',
                duration: Duration(seconds: 2),
              );
        } catch (e) {
          ref
              .read(snackBarQueueProvider.notifier)
              .showError('Failed to add contact: $e');
        }
      }

      if (!mounted) return;
      context.pop();
    }
  }

  String? _addressValidator(String? value) {
    final network = ref.read(settingsProvider.select((state) => state.network));
    if (value != null &&
        !isAddressValid(strAddress: value.trim(), network: network)) {
      return ref.read(appLocalizationsProvider).invalid_address_format_error;
    }
    return null;
  }
}
