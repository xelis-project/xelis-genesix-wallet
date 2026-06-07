import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/authentication_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/router/extra_codec.dart';
import 'package:genesix/features/router/transaction_entry_adapter.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'router.g.dart';

final routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

@riverpod
RouterRefreshNotifier routerRefreshListenable(Ref ref) {
  final notifier = RouterRefreshNotifier();
  ref.listen(
    authenticationProvider.select((auth) => auth.isAuth),
    (_, _) => notifier.refresh(),
  );
  ref.onDispose(notifier.dispose);
  return notifier;
}

@riverpod
GoRouter router(Ref ref) {
  final refreshNotifier = ref.watch(routerRefreshListenableProvider);
  final router = GoRouter(
    navigatorKey: routerKey,
    observers: kDebugMode ? [TalkerRouteObserver(talker)] : null,
    initialLocation: const OpenWalletRoute().location,
    refreshListenable: refreshNotifier,
    onException: (context, state, router) {
      // if exception like page not found just redirect to openWallet screen
      router.go(AppScreen.openWallet.toPath);
    },
    redirect: (context, state) {
      final isAuthenticated = ref.read(authenticationProvider).isAuth;

      if (!isAuthenticated) {
        for (final p in AuthAppScreen.values) {
          if (state.fullPath == p.toPath) {
            return AppScreen.openWallet.toPath;
          }
        }
        return null;
      }

      for (final p in const [
        AppScreen.openWallet,
        AppScreen.createWallet,
        AppScreen.importWallet,
      ]) {
        if (state.fullPath == p.toPath) {
          return AuthAppScreen.home.toPath;
        }
      }

      return null;
    },
    debugLogDiagnostics: true,
    routes: $appRoutes,
    extraCodec: const ExtraCodec(adapters: [TransactionEntryAdapter()]),
  );

  ref.onDispose(router.dispose);

  return router;
}
