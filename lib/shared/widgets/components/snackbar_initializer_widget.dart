import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/providers/snackbar_content_provider.dart';
import 'package:genesix/shared/providers/snackbar_event.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class SnackBarInitializerWidget extends ConsumerStatefulWidget {
  const SnackBarInitializerWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SnackBarInitializerWidget> createState() =>
      _SnackBarInitializerWidgetState();
}

class _SnackBarInitializerWidgetState
    extends ConsumerState<SnackBarInitializerWidget> {
  void _showInfoSnackBar(BuildContext context, Widget widget) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: widget,
        margin: const EdgeInsets.all(Spaces.large),
        duration:
            const Duration(milliseconds: AppDurations.displayTimeSnackbar),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: context.colors.onBackground,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, Widget widget) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: widget,
        margin: const EdgeInsets.all(Spaces.large),
        // long duration for error or we don't have time to see the error
        duration: const Duration(days: 1),
        dismissDirection: DismissDirection.down,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: context.colors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(snackbarContentProvider, (previous, next) {
      if (next != null) {
        switch (next) {
          case Info():
            _showInfoSnackBar(
              context,
              Text(
                next.message,
                style: context.bodyLarge,
              ),
            );
          case Error():
            _showErrorSnackBar(
              context,
              Text(
                next.message,
                style: context.bodyLarge?.copyWith(color: context.colors.error),
              ),
            );
        }
      }
    });
    return widget.child;
  }
}
