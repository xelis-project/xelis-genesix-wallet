import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class GenericAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GenericAppBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          context.pop();
        },
        icon: const Icon(
          Icons.arrow_back,
          // size: 30,
        ),
      ),
      title: Text(
        title,
        style: context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
