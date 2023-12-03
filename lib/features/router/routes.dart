import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/authentication_screen.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/settings_screen.dart';
import 'package:xelis_mobile_wallet/shared/widgets/hub_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<LoginRoute>(path: "/login")
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AuthenticationScreen();
  }
}

@TypedGoRoute<HubRoute>(path: "/hub")
class HubRoute extends GoRouteData {
  const HubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HubScreen();
  }
}

@TypedGoRoute<SettingsRoute>(path: "/settings")
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}
