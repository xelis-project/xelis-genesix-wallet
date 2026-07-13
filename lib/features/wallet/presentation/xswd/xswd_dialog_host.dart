import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

class XswdDialogHost extends ConsumerStatefulWidget {
  const XswdDialogHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<XswdDialogHost> createState() => _XswdDialogHostState();
}

class _XswdDialogHostState extends ConsumerState<XswdDialogHost> {
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(
      xswdDialogCoordinatorProvider,
      _onDialogOpenSignal,
      fireImmediately: true,
    );
  }

  void _onDialogOpenSignal(int? previous, int next) {
    final coordinator = ref.read(xswdDialogCoordinatorProvider.notifier);
    if (coordinator.claimOpenRequest(next)) {
      _openDialog();
    }
  }

  void _openDialog() {
    if (_isDialogOpen || !mounted) return;
    if (ref.read(settingsProvider).walletOfflineMode) {
      ref.read(xswdRequestProvider.notifier).clearRequest();
      return;
    }

    if (ref.read(xswdRequestProvider).xswdEventSummary == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDialogOpen) return;

      final navigatorContext = routerKey.currentState?.overlay?.context;
      if (navigatorContext == null) return;

      _isDialogOpen = true;
      showAppDialog<void>(
        context: navigatorContext,
        builder: (context, _, animation) => XswdDialog(animation),
      ).whenComplete(() {
        if (!mounted) return;

        _isDialogOpen = false;

        final xswdState = ref.read(xswdRequestProvider);
        final decision = xswdState.decision;
        if (decision != null && !decision.isCompleted) {
          decision.complete(UserPermissionDecision.reject);
        }

        ref.read(xswdRequestProvider.notifier).clearRequest();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
