import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

class XswdWidget extends ConsumerStatefulWidget {
  const XswdWidget(this.child, {super.key});

  final Widget child;

  static BuildContext? dialogContext;
  static WidgetRef? widgetRef;

  static void openDialog({required WidgetRef ref}) {
    final ctx = dialogContext;
    if (ctx == null || !ctx.mounted) return;

    // Avoid "open while toast overlay is dismissing"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;

      showFDialog<void>(
        context: ctx,
        useRootNavigator: true,
        builder: (context, style, animation) => XswdDialog(style, animation),
      ).then((_) {
        // Dialog closed - ensure decision is completed (handles barrier dismissal)
        final xswdState = ref.read(xswdRequestProvider);
        final decision = xswdState.decision;
        if (decision != null && !decision.isCompleted) {
          decision.complete(UserPermissionDecision.reject);
        }
        // Clear the request state to prevent stuck spinners
        ref.read(xswdRequestProvider.notifier).clearRequest();
      });
    });
  }

  @override
  ConsumerState<XswdWidget> createState() => _XswdWidgetState();
}

class _XswdWidgetState extends ConsumerState<XswdWidget> {
  @override
  Widget build(BuildContext context) {
    // Keep provider alive by watching it (like the old widget did)
    ref.watch(xswdRequestProvider);

    XswdWidget.dialogContext = context;
    XswdWidget.widgetRef = ref;

    return widget.child;
  }
}
