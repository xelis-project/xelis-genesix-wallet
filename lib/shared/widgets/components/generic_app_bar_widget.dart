import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/shared/theme/extensions.dart';

class GenericAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GenericAppBar({super.key, required this.title, this.actions});

  final String title;

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: Spaces.small,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(Spaces.small, Spaces.medium, 0, 0),
        child: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            // size: 30,
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.fromLTRB(0, Spaces.medium, 0, 0),
        child: Text(
          title,
          style: context.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
