import 'package:flutter/material.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:genesix/shared/widgets/components/global_bottom_loader_widget.dart';
import 'package:genesix/shared/widgets/components/snackbar_widget.dart';
import 'package:genesix/shared/widgets/components/providers_initializer_widget.dart';

import 'components/network_bar_widget.dart';

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SnackBarWidget(
      child: GlobalBottomLoader(
        child: ProvidersInitializerWidget(
          child: Material(
            child: Background(
              child: SafeArea(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NetworkTopWidget(),
                  Flexible(child: child),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}
