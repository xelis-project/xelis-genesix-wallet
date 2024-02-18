import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/shared/providers/scaffold_messenger_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

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
    ref.read(scaffoldMessengerPodProvider).showSnackBar(
          SnackBar(
            content: widget,
            duration: const Duration(milliseconds: 3000),
            width: 280.0,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.all(8.0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            showCloseIcon: true,
            closeIconColor: context.colors.primary,
          ),
        );
  }

  void _showErrorSnackBar(BuildContext context, Widget widget) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: widget,
        duration: const Duration(milliseconds: 3000),
        width: 280.0,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
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
                  style: context.bodyLarge
                      ?.copyWith(color: context.colors.primary),
                ));
          case Error():
            _showErrorSnackBar(
                context,
                Text(
                  next.message,
                  style:
                      context.bodyLarge?.copyWith(color: context.colors.error),
                ));
        }
      }
    });
    return widget.child;
  }
}
