import 'package:flutter/material.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog_host.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/toaster_widget.dart';
import 'package:genesix/shared/widgets/components/providers_initializer_widget.dart';

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return XswdDialogHost(
      child: ToasterWidget(
        child: ProvidersInitializerWidget(
          child: Material(
            child: ScrollConfiguration(
              behavior: context.scrollBehavior.copyWith(scrollbars: false),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
