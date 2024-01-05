import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/login_action_enum.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/authentication_screen.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/settings_tab_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/hub_screen.dart';

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
      return const AuthenticationScreen();
    }
  }
}

@TypedGoRoute<HubRoute>(name: 'hub', path: '/hub')
class HubRoute extends GoRouteData {
  const HubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HubScreen();
  }
}

@TypedGoRoute<SettingsRoute>(name: 'settings', path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsTab();
  }
}
