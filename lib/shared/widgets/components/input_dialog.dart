import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class InputDialog extends ConsumerStatefulWidget {
  final void Function(String value)? onEnter;

  const InputDialog({
    this.onEnter,
    super.key,
  });

  @override
  ConsumerState<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends ConsumerState<InputDialog> {
  final FocusNode _inputFocusNode = FocusNode();

  final _inputFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_inputFormKey');

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_inputFocusNode);

    return AlertDialog(
      scrollable: false,
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      iconPadding: const EdgeInsets.all(0),
      content: Builder(
        builder: (BuildContext context) {
          return FormBuilder(
            key: _inputFormKey,
            child: FormBuilderTextField(
              name: 'input',
              autocorrect: false,
              focusNode: _inputFocusNode,
              style: context.bodyLarge,
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
