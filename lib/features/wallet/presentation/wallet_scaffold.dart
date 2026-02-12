import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/wallet/presentation/side_bar/side_bar.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:go_router/go_router.dart';

class WalletScaffold extends ConsumerStatefulWidget {
  const WalletScaffold(
    this.goRouterState,
    this.child,
    this.title,
    this.headerSuffixes, {
    super.key,
  });

  final GoRouterState goRouterState;
  final Widget child;
  final String? title;
  final List<Widget>? headerSuffixes;

  @override
  ConsumerState createState() => _WalletScaffoldState();
}

class _WalletScaffoldState extends ConsumerState<WalletScaffold> {
  @override
  Widget build(BuildContext context) {
    final needTitle =
        widget.title != null && widget.title!.isNotEmpty && context.isMobile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // If already on home, do nothing (don't exit the app)
        if (context.goRouterState.fullPath == AuthAppScreen.home.toPath) {
          return;
        }

        // Otherwise, go back to home
        context.go(AuthAppScreen.home.toPath);
      },
      child: FScaffold(
        header: FHeader.nested(
          title: needTitle
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spaces.small),
                  child: Text(widget.title!),
                )
              : SizedBox.shrink(),
          prefixes: context.isMobile
              ? [
                  Padding(
                    padding: const EdgeInsets.all(Spaces.small),
                    child: FHeaderAction(
                      icon: const Icon(FIcons.menu),
                      onPress: () => showFSheet<void>(
                        context: context,
                        side: FLayout.ltr,
                        builder: (context) => SideBar(widget.goRouterState),
                      ),
                    ),
                  ),
                ]
              : [],
          suffixes: widget.headerSuffixes ?? [],
        ),
        sidebar: !context.isMobile ? SideBar(widget.goRouterState) : null,
        child: BodyLayoutBuilder(child: widget.child),
      ),
    );
  }
}
