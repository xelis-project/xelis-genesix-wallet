import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/router/login_action_codec.dart';
import 'package:xelis_mobile_wallet/features/router/routes.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');
  final isAuth = ValueNotifier<bool>(false);

  ref
    ..onDispose(isAuth.dispose)
    ..listen(
      authenticationProvider.select((value) => value.isAuth),
      (_, next) {
        isAuth.value = next;
      },
    );

  final router = GoRouter(
    navigatorKey: routerKey,
    refreshListenable: isAuth,
    initialLocation: const LoginRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
    extraCodec: const LoginActionCodec(),
    redirect: (context, state) {
      final loggingIn = state.fullPath == const LoginRoute().location;

      if (!isAuth.value) return loggingIn ? null : const LoginRoute().location;

      if (loggingIn) return const HubRoute().location;

      return null;
    },
  );

  ref.onDispose(router.dispose);

  return router;
}
