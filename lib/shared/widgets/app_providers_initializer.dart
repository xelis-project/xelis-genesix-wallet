import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/snackbar_initializer_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/wallet_initializer_widget.dart';

class AppProvidersInitializer extends StatelessWidget {
  const AppProvidersInitializer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SnackBarInitializerWidget(
        child: WalletInitializerWidget(child: child));
  }
}
