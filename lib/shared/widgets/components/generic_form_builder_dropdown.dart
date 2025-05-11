import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:genesix/shared/theme/extensions.dart';

class GenericFormBuilderDropdown<T> extends StatelessWidget {
  const GenericFormBuilderDropdown({
    super.key,
    required this.name,
    this.initialValue,
    required this.items,
    this.selectedItems,
    this.onChanged,
    this.validator,
    this.dropdownColor,
    this.enabled = true,
  });

  final String name;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final List<Widget>? selectedItems;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final Color? dropdownColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown<T>(
      name: name,
      initialValue: initialValue,
      enableFeedback: true,
      borderRadius: BorderRadius.circular(10),
      dropdownColor:
          dropdownColor ?? context.colors.surface.withValues(alpha: 0.9),
      focusColor: Colors.transparent,
      items: items,
      selectedItemBuilder:
          (selectedItems != null) ? (context) => selectedItems! : null,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
    );
  }
}
