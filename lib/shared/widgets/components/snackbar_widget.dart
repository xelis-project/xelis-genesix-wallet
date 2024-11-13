import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class SnackBarWidget extends ConsumerStatefulWidget {
  final Widget child;
  const SnackBarWidget({required this.child, super.key});

  @override
  ConsumerState<SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends ConsumerState<SnackBarWidget> {
  @override
  Widget build(BuildContext context) {
    final snackbarState = ref.watch(snackBarMessengerProvider);

    Color color;
    switch (snackbarState.type) {
      case SnackBarType.error:
        color = context.colors.error;
      case SnackBarType.info:
        color = context.colors.primary;
    }

    return Stack(
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutExpo,
          switchOutCurve: Curves.easeInExpo,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
                begin: const Offset(0, .3), end: const Offset(0, 0));
            return SlideTransition(
                position: offset.animate(animation), child: child);
          },
          child: switch (snackbarState.visible) {
            true => Align(
                key: UniqueKey(),
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.large),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      //border: Border.all(width: Spaces.medium),
                    ),
                    constraints: const BoxConstraints(
                        maxHeight: 200, minWidth: double.infinity),
                    child: Padding(
                      padding: const EdgeInsets.all(Spaces.medium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              snackbarState.message,
                              style: context.bodyLarge!.copyWith(color: color),
                            ),
                          ),
                          const SizedBox(width: Spaces.medium),
                          IconButton(
                            onPressed: () {
                              ref
                                  .read(snackBarMessengerProvider.notifier)
                                  .hide();
                            },
                            color: color,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            false => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}
