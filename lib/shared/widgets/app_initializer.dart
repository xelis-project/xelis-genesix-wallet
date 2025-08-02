import 'package:flutter/material.dart';
import 'package:genesix/shared/widgets/components/global_bottom_loader_widget.dart';
import 'package:genesix/shared/widgets/components/toaster_widget.dart';
import 'package:genesix/shared/widgets/components/providers_initializer_widget.dart';

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ToasterWidget(
      child: GlobalBottomLoader(
        child: ProvidersInitializerWidget(child: Material(child: child)),
      ),
    );
  }
}
