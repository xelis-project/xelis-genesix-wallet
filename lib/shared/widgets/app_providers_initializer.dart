import 'package:flutter/material.dart';
import 'package:genesix/shared/widgets/components/snackbar_widget.dart';
import 'package:genesix/shared/widgets/components/wallet_initializer_widget.dart';

class AppProvidersInitializer extends StatelessWidget {
  const AppProvidersInitializer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SnackBarWidget(
      child: WalletInitializerWidget(child: child),
    );
  }
}
