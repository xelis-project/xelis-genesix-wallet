import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class XswdWidget extends ConsumerStatefulWidget {
  const XswdWidget(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState createState() => _XswdWidgetState();
}

class _XswdWidgetState extends ConsumerState<XswdWidget> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.read(appLocalizationsProvider);
    final xswdState = ref.watch(xswdRequestProvider);

    final isCancelRequestOrAppDisconnect =
        xswdState.xswdEventSummary?.isCancelRequest() == true ||
        xswdState.xswdEventSummary?.isAppDisconnect() == true;

    return Stack(
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animNormal),
          switchInCurve: Curves.easeOutExpo,
          switchOutCurve: Curves.easeInExpo,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, -1),
              end: const Offset(0, 0),
            );
            return SlideTransition(
              position: offset.animate(animation),
              child: child,
            );
          },
          child: switch (xswdState.snackBarVisible) {
            true => Align(
              key: UniqueKey(),
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(Spaces.large),
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
                            xswdState.message,
                            style: context.bodyLarge,
                          ),
                        ),
                        if (!isCancelRequestOrAppDisconnect) ...[
                          const SizedBox(width: Spaces.medium),
                          TextButton(
                            onPressed: () => _onOpen(xswdState),
                            child: Text(loc.open_button),
                          ),
                        ],
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

  void _onOpen(XswdRequestState xswdState) {
    xswdState.snackBarTimer?.cancel();
    ref.read(xswdRequestProvider.notifier).closeSnackBar();
    _showXswdDialog();
  }

  void _showXswdDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return XswdDialog();
      },
    );
  }
}
