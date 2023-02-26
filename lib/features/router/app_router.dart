import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/authentication_screen.dart';
import 'package:xelis_mobile_wallet/features/authentication/providers/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/router/router_notifier.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/settings_screen.dart';
import 'package:xelis_mobile_wallet/shared/views/hub_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (state.location == AppScreen.settings.toPath) {
        return AppScreen.settings.toPath;
      }

      final isAuthenticated = ref.read(authenticationNotifierProvider);

      if (isAuthenticated) {
        return AppScreen.hub.toPath;
      } else {
        return AppScreen.auth.toPath;
      }
    },
    refreshListenable: RouterNotifier(ref),
    routes: [
      GoRoute(
        name: AppScreen.auth.toName,
        path: AppScreen.auth.toPath,
        builder: (context, _) => const AuthenticationScreen(),
      ),
      GoRoute(
        name: AppScreen.hub.toName,
        path: AppScreen.hub.toPath,
        builder: (context, _) => const HubScreen(),
      ),
      GoRoute(
        name: AppScreen.settings.toName,
        path: AppScreen.settings.toPath,
        builder: (context, _) => const SettingsScreen(),
      ),
    ],
  );
});
