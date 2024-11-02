import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'router.g.dart';

final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

@riverpod
GoRouter router(Ref ref) {
  final router = GoRouter(
    navigatorKey: routerKey,
    observers: kDebugMode ? [TalkerRouteObserver(talker)] : null,
    initialLocation: const OpenWalletRoute().location,
    onException: (context, state, router) {
      // if exception like page not found just redirect to openWallet screen
      router.go(AppScreen.openWallet.toPath);
    },
    redirect: (context, state) {
      // redirect to openWallet screen if wallet is not authenticated
      final auth = ref.read(authenticationProvider);
      if (!auth.isAuth) {
        for (final p in AuthAppScreen.values) {
          if (state.fullPath == p.toPath) {
            return AppScreen.openWallet.toPath;
          }
        }
      }

      return null;
    },
    debugLogDiagnostics: true,
    routes: $appRoutes,
  );

  ref.onDispose(router.dispose);

  return router;
}
