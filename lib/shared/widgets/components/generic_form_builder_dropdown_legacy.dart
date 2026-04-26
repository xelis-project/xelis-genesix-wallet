import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class GenericFormBuilderDropdown<T> extends StatelessWidget {
  const GenericFormBuilderDropdown({
    required this.name,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.dropdownColor,
    super.key,
  });

  final String name;
  final List<DropdownMenuItem<T>> items;
  final T? initialValue;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Color? dropdownColor;

  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown<T>(
      name: name,
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      dropdownColor: dropdownColor,
    );
  }
}
