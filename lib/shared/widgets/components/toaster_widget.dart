import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

class ToasterWidget extends ConsumerStatefulWidget {
  const ToasterWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ToasterWidget> createState() => _ToasterWidgetState();
}

class _ToasterWidgetState extends ConsumerState<ToasterWidget> {
  BuildContext? _toastContext;
  late BuildContext _appContext;

  bool _listenerSetup = false;

  bool _showDismissForWideScreen(BuildContext context) =>
      context.mediaWidth >= context.theme.breakpoints.md;

  void _setupToastListener() {
    if (_listenerSetup) return;
    _listenerSetup = true;

    ref.listen<ToastContent?>(toastProvider, (prev, next) {
      if (next == null) return;

      final toastCtx = _toastContext;
      if (toastCtx == null) return;

      switch (next.type) {
        case ToastType.information:
          showFToast(
            context: toastCtx,
            alignment: FToastAlignment.topCenter,
            duration: const Duration(seconds: 3),
            icon: const Icon(FIcons.info),
            title: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(next.title),
            ),
            suffixBuilder: _showDismissForWideScreen(toastCtx)
                ? (context, entry) => FButton.icon(
                    style: FButtonStyle.ghost(),
                    onPress: entry.dismiss,
                    child: const Icon(FIcons.x, size: 18),
                  )
                : null,
          );
          break;

        case ToastType.warning:
          showFToast(
            context: toastCtx,
            alignment: FToastAlignment.bottomCenter,
            duration: const Duration(seconds: 3),
            icon: const Icon(FIcons.triangleAlert),
            title: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(next.title),
            ),
            suffixBuilder: _showDismissForWideScreen(toastCtx)
                ? (context, entry) => FButton.icon(
                    style: FButtonStyle.ghost(),
                    onPress: entry.dismiss,
                    child: const Icon(FIcons.x, size: 18),
                  )
                : null,
          );
          break;

        case ToastType.error:
          showFToast(
            context: toastCtx,
            alignment: FToastAlignment.bottomRight,
            title: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                next.title,
                style: _appContext.theme.typography.base.copyWith(
                  color: _appContext.colors.error,
                ),
              ),
            ),
            description: next.description == null
                ? null
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(next.description!),
                  ),
            suffixBuilder: _showDismissForWideScreen(toastCtx)
                ? (context, entry) => FButton.icon(
                    style: FButtonStyle.ghost(),
                    onPress: entry.dismiss,
                    child: const Icon(FIcons.x, size: 18),
                  )
                : null,
          );
          break;

        case ToastType.event:
          showFToast(
            context: toastCtx,
            alignment: FToastAlignment.bottomRight,
            title: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(next.title),
            ),
            description: next.description == null
                ? null
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(next.description!),
                  ),
            suffixBuilder: _showDismissForWideScreen(toastCtx)
                ? (context, entry) => FButton.icon(
                    style: FButtonStyle.ghost(),
                    onPress: entry.dismiss,
                    child: const Icon(FIcons.x, size: 18),
                  )
                : null,
          );
          break;

        case ToastType.xswd:
          showFToast(
            context: toastCtx,
            alignment: FToastAlignment.topCenter,
            duration: next.sticky
                ? const Duration(days: 365)
                : const Duration(seconds: 3),
            icon: const Icon(FIcons.info),
            title: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(next.title),
            ),
            description: next.description == null
                ? null
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(next.description!),
                  ),
            suffixBuilder: (context, entry) {
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...next.actions.map(
                    (a) => FButton(
                      style: a.isPrimary
                          ? FButtonStyle.primary()
                          : FButtonStyle.ghost(),
                      onPress: () {
                        entry.dismiss();
                        ref
                            .read(xswdRequestProvider.notifier)
                            .requestOpenDialog();
                      },
                      child: Text(a.label),
                    ),
                  ),
                  if (next.dismissible) ...[
                    FButton.icon(
                      style: FButtonStyle.ghost(),
                      onPress: () {
                        // Clear the XSWD request state when toast is dismissed without opening dialog
                        ref.read(xswdRequestProvider.notifier).clearRequest();
                        entry.dismiss();
                      },
                      child: const Icon(FIcons.x, size: 18),
                    ),
                  ],
                ],
              );
            },
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _appContext = context;
    _setupToastListener();

    return FToaster(
      child: Builder(
        builder: (toastContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _toastContext = toastContext;
          });
          return widget.child;
        },
      ),
    );
  }
}
