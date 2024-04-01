import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/screens/authentication/presentation/authentication_screen.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/settings_screen.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_screen.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/widgets/snackbar_initializer_widget.dart';

part 'routes.g.dart';

@TypedGoRoute<AuthRoute>(name: 'auth', path: '/auth')
class AuthRoute extends GoRouteData {
  const AuthRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (state.extra is LoginAction) {
      return pageOf(
        AuthenticationScreen(
          loginAction: state.extra as LoginAction,
        ),
        state.pageKey,
        AppDurations.animFast,
      );
    } else {
      return pageOf(
        const SnackBarInitializerWidget(child: AuthenticationScreen()),
        state.pageKey,
        AppDurations.animFast,
      );
    }
  }
}

@TypedGoRoute<WalletRoute>(name: 'wallet', path: '/wallet')
class WalletRoute extends GoRouteData {
  const WalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageOf(
      const SnackBarInitializerWidget(child: WalletScreen()),
      state.pageKey,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<SettingsRoute>(name: 'settings', path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageOf(
      const SettingsScreen(),
      state.pageKey,
      AppDurations.animFast,
    );
  }
}

// This is the function to animate the transition between pages.
CustomTransitionPage<T> pageOf<T>(
        Widget child, ValueKey<String> pageKey, int milliDuration) =>
    CustomTransitionPage<T>(
      key: pageKey,
      child: child,
      transitionDuration: Duration(milliseconds: milliDuration),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeIn));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
        //return FadeTransition(opacity: animation, child: child);
      },
    );
