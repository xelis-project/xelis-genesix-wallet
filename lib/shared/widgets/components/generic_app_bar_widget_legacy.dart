import 'package:flutter/material.dart';

class GenericAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GenericAppBar({this.title, super.key});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: title != null ? Text(title!) : null);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
