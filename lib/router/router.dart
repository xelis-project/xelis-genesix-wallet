import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/router/routes.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

  /*
  final isAuth = ValueNotifier<bool>(false);

  ref
    ..onDispose(isAuth.dispose)
    ..listen(
      authenticationProvider.select((value) => value.isAuth),
      (_, next) {
        isAuth.value = next;
      },
    );*/

  final router = GoRouter(
    navigatorKey: routerKey,
    //refreshListenable: isAuth,
    initialLocation: const OpenWalletRoute().location, //const AuthRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
  
    //extraCodec: const LoginActionCodec(),
    /*redirect: (context, state) {
      final loggingIn = state.fullPath == const AuthRoute().location;

      if (!isAuth.value) return loggingIn ? null : const AuthRoute().location;

      if (loggingIn) return const WalletRoute().location;

      return null;
    },*/
  );

  ref.onDispose(router.dispose);

  return router;
}
