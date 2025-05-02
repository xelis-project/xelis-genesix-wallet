import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class SnackBarWidget extends ConsumerWidget {
  const SnackBarWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snackBars = ref.watch(snackBarQueueProvider);

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 60,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final snackbar in snackBars)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spaces.small),
                  child: _AnimatedSnackbar(snackbar: snackbar),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedSnackbar extends ConsumerStatefulWidget {
  final SnackBarState snackbar;

  const _AnimatedSnackbar({required this.snackbar});

  @override
  ConsumerState<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends ConsumerState<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snackbar = widget.snackbar;

    Color color;
    switch (snackbar.type) {
      case SnackBarType.error:
        color = context.colors.error;
      case SnackBarType.info:
        color = context.colors.primary;
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(Spaces.medium),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  snackbar.message,
                  style: context.bodyLarge!.copyWith(color: color),
                ),
              ),
              const SizedBox(width: Spaces.medium),
              IconButton(
                onPressed: () {
                  ref.read(snackBarQueueProvider.notifier).remove(snackbar.id);
                },
                color: color,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
