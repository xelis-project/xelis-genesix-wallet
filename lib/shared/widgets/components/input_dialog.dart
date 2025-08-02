import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration_old.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';

class InputDialog extends ConsumerStatefulWidget {
  final String title;
  final String? hintText;
  final void Function(String value)? onEnter;

  const InputDialog({
    required this.title,
    this.onEnter,
    this.hintText,
    super.key,
  });

  @override
  ConsumerState<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends ConsumerState<InputDialog> {
  final _inputFormKey = GlobalKey<FormBuilderState>(
    debugLabel: '_inputFormKey',
  );

  late FocusNode _focusNodeInput;

  @override
  void initState() {
    super.initState();
    _focusNodeInput = FocusNode();
  }

  @override
  void dispose() {
    _focusNodeInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return GenericDialog(
      scrollable: false,
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
                  widget.title,
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
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Builder(
        builder: (BuildContext context) {
          return FormBuilder(
            key: _inputFormKey,
            child: FormBuilderTextField(
              name: 'input',
              focusNode: _focusNodeInput,
              autocorrect: false,
              autofocus: true,
              style: context.bodyLarge,
              decoration: context.textInputDecoration.copyWith(
                hintText: widget.hintText,
              ),
              onChanged: (value) {
                // workaround to reset the error message when the user modifies the field
                final hasError =
                    _inputFormKey.currentState?.fields['input']?.hasError;
                if (hasError ?? false) {
                  _inputFormKey.currentState?.fields['input']?.reset();
                }
              },
              onSubmitted: (value) {
                if (widget.onEnter != null &&
                    (_inputFormKey.currentState?.saveAndValidate() ?? false)) {
                  _focusNodeInput.unfocus();
                  widget.onEnter!(value!);
                }
              },
              validator: FormBuilderValidators.required(
                errorText: loc.field_required_error,
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            if (_inputFormKey.currentState?.saveAndValidate() ?? false) {
              if (widget.onEnter != null) {
                _focusNodeInput.unfocus();
                widget.onEnter!(
                  _inputFormKey.currentState!.fields['input']!.value as String,
                );
              }
            }
          },
          label: Text(loc.confirm_button),
          // icon: Icon(
          //   Icons.check,
          //   size: 18,
          // ),
        ),
      ],
    );
  }
}
