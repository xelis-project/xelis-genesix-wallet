import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/router/routes.dart';

part 'router.g.dart';

final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

@riverpod
GoRouter router(RouterRef ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

  final router = GoRouter(
    navigatorKey: routerKey,
    initialLocation:
        const OpenWalletRoute().location, //const AuthRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
  );

  ref.onDispose(router.dispose);

  return router;
}
