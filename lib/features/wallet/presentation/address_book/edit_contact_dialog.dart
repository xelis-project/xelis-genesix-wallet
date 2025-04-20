import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';

class EditContactDialog extends ConsumerStatefulWidget {
  const EditContactDialog(this.address, {super.key});

  final String address;

  @override
  ConsumerState<EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends ConsumerState<EditContactDialog> {
  final _formKey = GlobalKey<FormBuilderState>(
    debugLabel: '_editContactFormKey',
  );
  late FocusNode _focusNodeName;

  @override
  void initState() {
    super.initState();
    _focusNodeName = FocusNode();
    _focusNodeName.requestFocus();
  }

  @override
  void dispose() {
    _focusNodeName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final future = ref.watch(addressBookProvider.notifier).get(widget.address);

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
                  'Edit contact',
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
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.address,
            style: context.titleSmall?.copyWith(
              color: context.moreColors.mutedColor,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(widget.address, style: context.bodyLarge),
          const SizedBox(height: Spaces.large),
          FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.name.capitalize(),
                  style: context.titleSmall?.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                FutureBuilder(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return FormBuilderTextField(
                        name: 'name',
                        focusNode: _focusNodeName,
                        style: context.bodyLarge,
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        decoration: context.textInputDecoration,
                        initialValue: snapshot.data?.name,
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: TextButton(onPressed: _save, child: Text(loc.save)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      _focusNodeName.unfocus();
      final name = _formKey.currentState?.fields['name']?.value as String?;
      if (name != null) {
        try {
          await ref
              .read(addressBookProvider.notifier)
              .upsert(widget.address, name.trim(), null);
          ref
              .read(snackBarMessengerProvider.notifier)
              .showInfo('contact updated', durationInSeconds: 2);
        } catch (e) {
          ref
              .read(snackBarMessengerProvider.notifier)
              .showError('Failed to update contact: $e');
        }
      }

      if (!mounted) return;
      context.pop();
    }
  }
}
