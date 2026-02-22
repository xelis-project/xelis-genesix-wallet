import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/theme/dialog_style.dart';

import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

class XswdWidget extends ConsumerStatefulWidget {
  const XswdWidget(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<XswdWidget> createState() => _XswdWidgetState();
}

class _XswdWidgetState extends ConsumerState<XswdWidget> {
  bool _isDialogOpen = false;

  void _openDialog() {
    if (_isDialogOpen || !mounted) return;

    // Avoid "open while toast overlay is dismissing"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDialogOpen) return;

      _isDialogOpen = true;
      showAppDialog<void>(
        context: context,
        builder: (context, _, animation) => XswdDialog(animation),
      ).whenComplete(() {
        _isDialogOpen = false;

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
  Widget build(BuildContext context) {
    // Keep provider alive by watching it (like the old widget did)
    ref.watch(xswdRequestProvider);

    ref.listen<int>(xswdDialogOpenSignalProvider, (previous, next) {
      if (previous == next) return;
      _openDialog();
    });

    return widget.child;
  }
}
