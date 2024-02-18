import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/authentication_screen.dart';
import 'package:xelis_mobile_wallet/shared/widgets/hub_screen.dart';
import 'package:xelis_mobile_wallet/shared/widgets/snackbar_initializer_widget.dart';

part 'routes.g.dart';

@TypedGoRoute<LoginRoute>(name: 'login', path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    if (state.extra is LoginAction) {
      return AuthenticationScreen(
        loginAction: state.extra as LoginAction,
      );
    } else {
      return const SnackBarInitializerWidget(child: AuthenticationScreen());
    }
  }
}

@TypedGoRoute<HubRoute>(name: 'hub', path: '/hub')
class HubRoute extends GoRouteData {
  const HubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SnackBarInitializerWidget(child: HubScreen());
  }
}
