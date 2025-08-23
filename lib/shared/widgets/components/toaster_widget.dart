import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

class ToasterWidget extends ConsumerStatefulWidget {
  const ToasterWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ToasterWidget> createState() => _ToasterWidgetState();
}

class _ToasterWidgetState extends ConsumerState<ToasterWidget> {
  late BuildContext _toastContext;
  FToasterExpandBehavior _fToasterExpandBehavior =
      FToasterExpandBehavior.hoverOrPress;

  // TODO check possible description content overflow

  void _setupToastListener() {
    ref.listen<ToastContent?>(toastProvider, (prev, next) {
      if (next != null) {
        switch (next.type) {
          case ToastType.information:
            setState(() {
              _fToasterExpandBehavior = FToasterExpandBehavior.disabled;
            });
            showFToast(
              context: _toastContext,
              alignment: FToastAlignment.topCenter,
              duration: Duration(seconds: 3),
              icon: const Icon(FIcons.info),
              title: Text(next.title),
            );
            break;
          case ToastType.warning:
            setState(() {
              _fToasterExpandBehavior = FToasterExpandBehavior.disabled;
            });
            showFToast(
              context: _toastContext,
              alignment: FToastAlignment.bottomCenter,
              duration: Duration(seconds: 3),
              icon: const Icon(FIcons.triangleAlert),
              title: Text(next.title),
            );
            break;
          case ToastType.error:
            setState(() {
              _fToasterExpandBehavior = FToasterExpandBehavior.hoverOrPress;
            });
            showFToast(
              context: _toastContext,
              alignment: FToastAlignment.bottomRight,
              title: Text(
                next.title,
                style: context.theme.typography.base.copyWith(
                  color: context.colors.error,
                ),
              ),
              description: Text(next.description!),
              suffixBuilder: (context, entry) => IntrinsicHeight(
                child: FButton(
                  style: context.theme.buttonStyles.primary
                      .copyWith(
                        contentStyle: context
                            .theme
                            .buttonStyles
                            .primary
                            .contentStyle
                            .copyWith(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7.5,
                              ),
                              textStyle: FWidgetStateMap.all(
                                context.theme.typography.xs.copyWith(
                                  color: context.theme.colors.primaryForeground,
                                ),
                              ),
                            )
                            .call,
                      )
                      .call,
                  onPress: entry.dismiss,
                  child: const Text('Undo'),
                ),
              ),
            );
            break;
          case ToastType.event:
            setState(() {
              _fToasterExpandBehavior = FToasterExpandBehavior.hoverOrPress;
            });
            showFToast(
              context: _toastContext,
              alignment: FToastAlignment.bottomRight,
              title: Text(next.title),
              description: Text(next.description!),
              suffixBuilder: (context, entry) => IntrinsicHeight(
                child: FButton(
                  style: context.theme.buttonStyles.primary
                      .copyWith(
                        contentStyle: context
                            .theme
                            .buttonStyles
                            .primary
                            .contentStyle
                            .copyWith(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7.5,
                              ),
                              textStyle: FWidgetStateMap.all(
                                context.theme.typography.xs.copyWith(
                                  color: context.theme.colors.primaryForeground,
                                ),
                              ),
                            )
                            .call,
                      )
                      .call,
                  onPress: entry.dismiss,
                  child: const Text('Undo'),
                ),
              ),
            );
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _setupToastListener();

    return FToaster(
      style: (style) => style.copyWith(expandBehavior: _fToasterExpandBehavior),
      child: Builder(
        builder: (toastContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _toastContext = toastContext;
          });
          return widget.child;
        },
      ),
    );
  }
}
