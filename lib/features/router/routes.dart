import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/authentication_screen.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/change_password_screen.dart';
import 'package:xelis_mobile_wallet/shared/widgets/hub_screen.dart';
import 'package:xelis_mobile_wallet/shared/widgets/snackbar_initializer_widget.dart';

part 'routes.g.dart';

@TypedGoRoute<LoginRoute>(name: 'login', path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (state.extra is LoginAction) {
      return pageOf(
          AuthenticationScreen(
            loginAction: state.extra as LoginAction,
          ),
          state.pageKey);
    } else {
      return pageOf(
          const SnackBarInitializerWidget(child: AuthenticationScreen()),
          state.pageKey);
    }
  }
}

@TypedGoRoute<HubRoute>(name: 'hub', path: '/hub')
class HubRoute extends GoRouteData {
  const HubRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageOf(
        const SnackBarInitializerWidget(child: HubScreen()), state.pageKey);
  }
}

@TypedGoRoute<ChangePasswordRoute>(
    name: 'change_password', path: '/change_password')
class ChangePasswordRoute extends GoRouteData {
  const ChangePasswordRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageOf(const ChangePasswordScreen(), state.pageKey);
  }
}

CustomTransitionPage<T> pageOf<T>(Widget child, ValueKey<String> pageKey) =>
    CustomTransitionPage<T>(
      key: pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, animation2, child) =>
          FadeTransition(opacity: animation, child: child),
    );
