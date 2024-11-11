import 'package:flutter/material.dart';

extension InputDecorationUtils on BuildContext {
  InputDecoration get textInputDecoration => InputDecoration(
        errorMaxLines: 2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(this).colorScheme.onSurface.withOpacity(0.5),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(this).colorScheme.onSurface,
            width: 2,
          ),
        ),
      );
}
