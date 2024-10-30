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
    return Row(
      children: [
        if (context.isWideScreen) Spacer(),
        Flexible(
          flex: 2,
          child: AppBar(
            titleSpacing: Spaces.small,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spaces.small, Spaces.medium, Spaces.none, Spaces.none),
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
              padding: const EdgeInsets.fromLTRB(
                  Spaces.none, Spaces.medium, Spaces.none, Spaces.none),
              child: Text(
                title,
                style: context.headlineMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            actions: actions,
          ),
        ),
        if (context.isWideScreen) Spacer(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
