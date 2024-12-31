import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/shared/theme/extensions.dart';

class GenericAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GenericAppBar(
      {super.key,
      this.title,
      this.actions,
      this.implyLeading = false,
      this.onBack});

  final String? title;
  final List<Widget>? actions;
  final bool implyLeading;
  final void Function()? onBack;

  @override
  Widget build(BuildContext context) {
    final onPressedBack = onBack ?? () => context.pop();
    return Row(
      children: [
        if (context.isWideScreen) Spacer(),
        Flexible(
          flex: 2,
          child: AppBar(
            automaticallyImplyLeading: implyLeading,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            title: title != null
                ? Padding(
                    padding: const EdgeInsets.only(top: Spaces.medium),
                    child: Text(
                      title!,
                      style: context.headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            actions: [
              if (actions != null) ...actions!,
              Padding(
                padding: const EdgeInsets.only(right: Spaces.small),
                child: Center(
                  child: IconButton(
                    onPressed: onPressedBack,
                    icon: Icon(Icons.close_rounded),
                  ),
                ),
              )
            ],
          ),
        ),
        if (context.isWideScreen) Spacer(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
