import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordTextField extends ConsumerStatefulWidget {
  final FormBuilderTextField textField;

  const PasswordTextField({required this.textField, super.key});

  @override
  ConsumerState<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends ConsumerState<PasswordTextField> {
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      // changed
      name: widget.textField.name,
      obscureText: _hidePassword,
      decoration: widget.textField.decoration.copyWith(
        suffixIcon: IconButton(
          hoverColor: Colors.transparent,
          icon: _hidePassword
              ? const Icon(Icons.visibility_off_rounded)
              : const Icon(Icons.visibility_rounded),
          onPressed: () {
            setState(() {
              _hidePassword = !_hidePassword;
            });
          },
        ),
      ),
      // initial
      key: widget.textField.key,
      initialValue: widget.textField.initialValue,
      controller: widget.textField.controller,
      focusNode: widget.textField.focusNode,
      keyboardType: widget.textField.keyboardType,
      textInputAction: widget.textField.textInputAction,
      textCapitalization: widget.textField.textCapitalization,
      style: widget.textField.style,
      strutStyle: widget.textField.strutStyle,
      textAlign: widget.textField.textAlign,
      textAlignVertical: widget.textField.textAlignVertical,
      autofocus: widget.textField.autofocus,
      readOnly: widget.textField.readOnly,
      showCursor: widget.textField.showCursor,
      autocorrect: widget.textField.autocorrect,
      maxLines: widget.textField.maxLines,
      minLines: widget.textField.minLines,
      maxLength: widget.textField.maxLength,
      buildCounter: widget.textField.buildCounter,
      maxLengthEnforcement: widget.textField.maxLengthEnforcement,
      onChanged: widget.textField.onChanged,
      onTap: widget.textField.onTap,
      onEditingComplete: widget.textField.onEditingComplete,
      onSaved: widget.textField.onSaved,
      validator: widget.textField.validator,
      inputFormatters: widget.textField.inputFormatters,
      enabled: widget.textField.enabled,
      cursorWidth: widget.textField.cursorWidth,
      cursorHeight: widget.textField.cursorHeight,
      cursorRadius: widget.textField.cursorRadius,
      cursorColor: widget.textField.cursorColor,
      keyboardAppearance: widget.textField.keyboardAppearance,
      scrollPadding: widget.textField.scrollPadding,
      enableInteractiveSelection: widget.textField.enableInteractiveSelection,
      autofillHints: widget.textField.autofillHints,
      scrollController: widget.textField.scrollController,
      scrollPhysics: widget.textField.scrollPhysics,
      restorationId: widget.textField.restorationId,
      dragStartBehavior: widget.textField.dragStartBehavior,
      mouseCursor: widget.textField.mouseCursor,
      autovalidateMode: widget.textField.autovalidateMode,
      contentInsertionConfiguration:
          widget.textField.contentInsertionConfiguration,
      contextMenuBuilder: widget.textField.contextMenuBuilder,
      enableSuggestions: widget.textField.enableSuggestions,
      expands: widget.textField.expands,
      magnifierConfiguration: widget.textField.magnifierConfiguration,
      obscuringCharacter: widget.textField.obscuringCharacter,
      onReset: widget.textField.onReset,
      onSubmitted: widget.textField.onSubmitted,
      onTapOutside: widget.textField.onTapOutside,
      selectionHeightStyle: widget.textField.selectionHeightStyle,
      selectionWidthStyle: widget.textField.selectionWidthStyle,
      smartDashesType: widget.textField.smartDashesType,
      smartQuotesType: widget.textField.smartQuotesType,
      spellCheckConfiguration: widget.textField.spellCheckConfiguration,
      textDirection: widget.textField.textDirection,
      valueTransformer: widget.textField.valueTransformer,
    );
  }
}
