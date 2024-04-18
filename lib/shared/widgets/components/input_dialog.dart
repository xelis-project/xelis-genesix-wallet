import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class InputDialog extends ConsumerStatefulWidget {
  final String? hintText;
  final void Function(String value)? onEnter;

  const InputDialog({
    this.onEnter,
    this.hintText,
    super.key,
  });

  @override
  ConsumerState<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends ConsumerState<InputDialog> {
  final _inputFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_inputFormKey');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      contentPadding: const EdgeInsets.all(Spaces.small),
      content: Builder(
        builder: (BuildContext context) {
          return FormBuilder(
            key: _inputFormKey,
            child: FormBuilderTextField(
              name: 'input',
              autocorrect: false,
              autofocus: true,
              style: context.bodyLarge,
              decoration: InputDecoration(
                fillColor: Colors.transparent,
                hintText: widget.hintText,
              ),
              onSubmitted: (value) {
                if (widget.onEnter != null) {
                  widget.onEnter!(value!);
                }
              },
              validator: FormBuilderValidators.required(),
            ),
          );
        },
      ),
    );
  }
}
