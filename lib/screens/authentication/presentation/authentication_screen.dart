import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/screens/authentication/presentation/create_wallet_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/screens/authentication/presentation/open_wallet_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';

class AuthenticationScreen extends ConsumerWidget {
  const AuthenticationScreen({super.key, LoginAction? loginAction})
      : explicitAction = loginAction;

  final LoginAction? explicitAction;

  Widget _getScaffold(BuildContext context, Widget child) {
    return Scaffold(
      body: Background(child: child),
    );
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: context.mediaSize.height),
                  child: child))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (explicitAction) {
      case LoginAction.create:
        return _getScaffold(context, const CreateWalletWidget());
      case LoginAction.open:
        return _getScaffold(context, const OpenWalletWidget());
      case null:
        return _getScaffold(context, const OpenWalletWidget());
      /*final data = ref.watch(openWalletProvider);
        return data.wallets.isNotEmpty
            ? _getScaffold(context, const OpenWalletWidget())
            : _getScaffold(context, const CreateWalletWidget());*/
    }
  }
}
