import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:genesix/features/authentication/presentation/components/seed_content_dialog.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/burn_screen.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/widgets/components/dialog_page.dart';
import 'package:genesix/features/logger/presentation/logger_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/authentication/presentation/create_wallet_screen.dart';
import 'package:genesix/features/authentication/presentation/open_wallet_screen.dart';
import 'package:genesix/features/settings/presentation/settings_screen.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_screen.dart';
import 'package:genesix/features/wallet/presentation/settings_tab/components/change_password_screen.dart';
import 'package:genesix/features/wallet/presentation/settings_tab/components/my_seed_screen.dart';
import 'package:genesix/features/wallet/presentation/wallet_screen.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/components/transfer_screen.dart';
import 'package:genesix/shared/theme/constants.dart';

part 'routes.g.dart';

@TypedGoRoute<OpenWalletRoute>(name: 'open_wallet', path: '/open_wallet')
class OpenWalletRoute extends GoRouteData {
  const OpenWalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const OpenWalletScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<CreateWalletRoute>(name: 'create_wallet', path: '/create_wallet')
class CreateWalletRoute extends GoRouteData {
  const CreateWalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const CreateWalletScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<ChangePasswordRoute>(
    name: 'change_password', path: '/change_password')
class ChangePasswordRoute extends GoRouteData {
  const ChangePasswordRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const ChangePasswordScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<WalletSeedRoute>(name: 'wallet_seed', path: '/wallet_seed')
class WalletSeedRoute extends GoRouteData {
  const WalletSeedRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const MySeedScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<WalletSeedDialogRoute>(
    name: 'wallet_seed_dialog', path: '/wallet_seed_dialog')
class WalletSeedDialogRoute extends GoRouteData {
  const WalletSeedDialogRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return DialogPage(
        barrierDismissible: false,
        builder: (_) => SeedContentDialog(state.extra as String));
  }
}

@TypedGoRoute<WalletRoute>(name: 'wallet', path: '/wallet')
class WalletRoute extends GoRouteData {
  const WalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const WalletScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<SettingsRoute>(name: 'settings', path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const SettingsScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<TransferRoute>(name: 'transfer', path: '/transfer')
class TransferRoute extends GoRouteData {
  const TransferRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const TransferScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<BurnRoute>(name: 'burn', path: '/burn')
class BurnRoute extends GoRouteData {
  const BurnRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const BurnScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<TransactionEntryRoute>(
    name: 'transaction_entry', path: '/transaction_entry')
class TransactionEntryRoute extends GoRouteData {
  const TransactionEntryRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      TransactionEntryScreen(routerState: state),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

@TypedGoRoute<TalkerScreenRoute>(name: 'logger', path: '/logger')
class TalkerScreenRoute extends GoRouteData {
  const TalkerScreenRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      LoggerScreen(talker: talker),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animFast,
    );
  }
}

// This is the function to animate the transition between pages.
CustomTransitionPage<T> pageTransition<T>(
        Widget child,
        ValueKey<String> pageKey,
        String? path,
        Object? arguments,
        int milliDuration) =>
    CustomTransitionPage<T>(
      key: pageKey,
      name: path,
      child: child,
      arguments: arguments,
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
