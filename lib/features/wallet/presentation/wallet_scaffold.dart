import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/side_bar/side_bar.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:go_router/go_router.dart';

class WalletScaffold extends ConsumerStatefulWidget {
  const WalletScaffold(
    this.child,
    this.title,
    this.headerSuffixes, {
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? headerSuffixes;

  @override
  ConsumerState createState() => _WalletScaffoldState();
}

class _WalletScaffoldState extends ConsumerState<WalletScaffold> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && context.canPop()) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final needTitle = widget.title != null && widget.title!.isNotEmpty && context.isMobile;

    return FScaffold(
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
                      builder: (context) => SideBar(),
                    ),
                  ),
                ),
              ]
            : [],
        suffixes: widget.headerSuffixes ?? [],
      ),
      sidebar: !context.isMobile ? SideBar() : null,
      child: BodyLayoutBuilder(child: widget.child),
    );
  }
}
